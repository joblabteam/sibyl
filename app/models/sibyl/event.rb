module Sibyl
  class Event < ActiveRecord::Base
    after_commit :queue_triggers, on: :create

    # with the need to denormalize data (extracting objects ids to the Sibyl::Event
    # instance, we have this method including the ids we want to save.
    # example: { candidate_id: 1, vacancy_id: 23 }
    def self.record(kind:, occurred_at: Time.now, data: {}, ids: {})
      new(
        kind: kind,
        occurred_at: occurred_at,
        data: data
      ).normalized_ids(ids)
        .save!
    rescue ActiveRecord::RecordInvalid
      false
    end

    def normalized_ids(ids)
      ids.each_pair do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
      self
    end

    # `record` is now the preferred name
    # singleton_class.send :alias_method, :record, :create_event
    def self.create_event(kind, occurred_at = Time.now, data)
      puts "Sibyl Depreciation: use `record` instead of `create_event` " \
           "#{caller_locations(1, 1)[0]}"
      record(kind, occurred_at, data)
    end

    # Override the default `data` field accessor to allow indifferent access.
    # Often used in Triggers.
    #
    #   event.data["foo"]["bar"]["baz"]
    #
    #   # becomes:
    #   event.data[:foo][:bar][:baz]
    def data
      self[:data].with_indifferent_access
    end

    def ids
      self[:ids].with_indifferent_access
    end

    def queue_triggers
      triggers = TRIGGERS.select do |trigger, _actions|
        if trigger.is_a?(Regexp)
          kind =~ trigger
        else
          kind == trigger
        end
      end

      triggers.each do |_trigger, actions|
        actions.each do |action|
          if action.delayed?
            delay = action.delay
            delay = delay.call(self) if delay.respond_to?(:call)
            SibylTriggerWorker.perform_in(delay, action.call_class, kind, id)
          else
            SibylTriggerWorker.perform_async(action.call_class, kind, id)
          end
        end
      end
    end

    def self.filter_property?(property)
      if property.blank?
        all
      else
        properties = property_array(property)

        query = ""
        properties.each_with_index do |prop, i|
          # data?'foo' AND data->'foo'?'bar' AND data->'foo'->'bar'?'baz'
          query += " AND " unless i == 0
          query += "data"
          query += "->" unless properties[0...i].empty?
          query += properties[0...i].join("->")
          query += "?#{prop}"
        end

        where(query)
      end
    end

    def self.filter_property_value(filter, property, value)
      if property.blank? || value.blank?
        all
      else
        property = property_query(property)

        query = case filter.to_s
                when "eq"
                  "(#{property})::text = '#{value}'"
                when "ne"
                  "(#{property})::text != '#{value}'"
                when "lt"
                  "(#{property})::text::float < #{value}"
                when "lte"
                  "(#{property})::text::float <= #{value}"
                when "gt"
                  "(#{property})::text::float > #{value}"
                when "gte"
                  "(#{property})::text::float >= #{value}"
                when "like"
                  "(#{property})::text LIKE '#{value}'"
                when "not_like"
                  "(#{property})::text NOT LIKE '#{value}'"
                when "blank"
                  "(#{property})::text IS NULL OR (#{property})::text = 'null' OR (#{property})::text = '\"\"'"
                when "not_blank"
                  "(#{property})::text IS NOT NULL AND (#{property})::text != 'null' AND (#{property})::text != '\"\"'"
                when "contains"
                  "#{property} @> '#{value}'::jsonb"
                when "contained"
                  "#{property} <@ '#{value}'::jsonb"
                when "one_key"
                  "#{property} ? '#{value}'"
                when "any_keys"
                  "#{property} ?| array[#{property_array(value).join(', ')}]"
                when "all_keys"
                  "#{property} ?& array[#{property_array(value).join(', ')}]"
                end

        where(query)
      end
    end

    def self.group_by(property, order)
      order = order.blank? ? "DESC" : order
      property = property_query(property)

      reorder("(#{property})::text #{order}")
        .group("(#{property})::text")
    end

    def self.operation(op, property, order, primitive: true)
      order = safe_order(order)
      # property = property_query(as, property)

      case op
      when "all"
        # count
        safe_op(:x, primitive) do |sc|
          sc.select("(#{property})::text AS #{property.gsub('data->', '').gsub('->', '_').gsub("'", '').gsub(/\W/, '')}, occurred_at AS interval")
        end
      when "count"
        # count
        safe_op(:count, primitive) do |sc|
          sc.select("COUNT(*)")
        end
      when "uniq"
        # reorder("").distinct.count("(#{property})::text")
        safe_op(:count, primitive) do |sc|
          # sc.select("DISTINCT COUNT(DISTINCT (#{property})::text)")
          # Optimized:
          # in PG `SELECT count(DISTINCT prop)` is a bit slower than
          # `SELECT count(*) FROM (SELECT DISTINCT prop)`
          unscoped.select("count(*)").from(
            sc.select(property).distinct.reorder("")
          )
        end
      when "group"
        safe_op(:count, primitive) do |sc|
          sc.reorder("(#{property})::text #{order}")
            .group("(#{property})::text").count # ("(#{property})::text")
        end
      when "min"
        safe_op(:min, primitive) do |sc|
          sc.select("MIN((#{property})::text::float)")
        end
      when "max"
        safe_op(:max, primitive) do |sc|
          sc.select("MAX((#{property})::text::float)")
        end
      when "avg"
        safe_op(:avg, primitive) do |sc|
          sc.select("AVG((#{property})::text::float)")
        end
      when "sum"
        safe_op(:sum, primitive) do |sc|
          sc.select("SUM((#{property})::text::float)")
        end
      when "min_length"
        safe_op(:min, primitive) do |sc|
          sc.select("MIN(LENGTH((#{property})::text))")
        end
      when "max_length"
        safe_op(:max, primitive) do |sc|
          sc.select("MAX(LENGTH((#{property})::text))")
        end
      when "avg_length"
        safe_op(:avg, primitive) do |sc|
          sc.select("AVG(LENGTH((#{property})::text))")
        end
      else
        where(nil)
      end
    end

    def self.interval(interval)
      # WARNING POTENTIAL FOR SQL INJECTION BELOW!!!
      if %w(second minute hour day week month quarter year).include? interval
        @danger_order = false
        select("date_trunc('#{interval}', occurred_at) AS \"interval\"")
          .reorder('"interval" ASC')
          .group('"interval"')
      end
    end

    def self.order_by(order)
      order = safe_order(order)
      @danger_order = true

      order(occurred_at: order.to_sym)
    end

    def self.in_kind(kind)
      if kind.blank?
        all
      else
        kind = kind.split(",").map(&:strip)
        where(kind: kind) # WHERE kind IN ('foo', 'bar')
      end
    end

    def self.date_from(from)
      where("occurred_at >= ?", from) unless from.blank?
    end

    def self.date_to(to)
      where("occurred_at <= ?", to) unless to.blank?
    end

    def self.date_previous(previous)
      where("occurred_at >= (current_timestamp - INTERVAL ?)", previous)
    end

    def self.date_previous_to(previous)
      where("occurred_at <= (current_timestamp - INTERVAL ?)", previous)
    end

    def self.property_array(property)
      property.split(",").map { |p| "'#{p.strip}'" } unless property.blank?
    end

    def self.property_query(property)
      "data->#{property_array(property).join('->')}" unless property.blank?
    end

    def self.safe_order(order)
      order.blank? || order == "desc" ? "DESC" : order
    end

    def self.safe_op(op, primitive)
      sc = where(nil)
      sc = sc.reorder("") if @danger_order
      sc = yield(sc)
      if primitive
        # sc.inspect # this is needed to kick AR into action
        # the `to_a` below is needed to kick AR into action
        if sc.to_a.size == 1
          sc[0][op]
        else
          # Hash is the time interval, AR::Relation is group by uniq
          sc = sc.map do |v|
            v.is_a?(Array) ? v : v.serializable_hash.reject { |k| k == "id" }
          end unless sc.is_a?(Hash)
          sc
        end
      else
        sc
      end
    end

    def self.where_funnel(property, last_property, relation)
      relation = relation.filter_property?(last_property).reorder("")
      relation = relation.select(property_query(last_property))

      filter_property?(property).where("#{property_query(property)} IN (#{relation.to_sql})")
    end

    # def self.where_funnel(i, property, last_property, relation, period_to)
      # p property
      # p last_property
      # relation = relation.filter_property?("a#{i - 1}", last_property)
                         # .select("MIN(a#{i - 1}.occurred_at) AS occurred_at, #{property_query("a#{i - 1}", last_property)} AS jid")
      # relation = relation.group(property_query("a#{i - 1}", last_property)).reorder("")

      # new_rel = from("sibyl_events AS a#{i}")
                # .filter_property?("a#{i}", property)
                # .joins("INNER JOIN (#{relation.to_sql}) o#{i} ON o#{i}.jid = #{property_query("a#{i}", property)}")
      # new_rel = new_rel.where("a#{i}.occurred_at >= o#{i}.occurred_at")
      # new_rel = new_rel.where("a#{i}.occurred_at <= (o#{i}.occurred_at + INTERVAL ?)", period_to) unless period_to.blank?
      # new_rel
    # end
  end
end
