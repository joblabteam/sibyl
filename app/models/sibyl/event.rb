module Sibyl
  class Event < ActiveRecord::Base
    after_commit :queue_triggers, on: :create

    def self.create_event(kind, occurred_at = Time.now, data)
      create!(
        kind: kind,
        occurred_at: occurred_at,
        data: data
      )
    rescue ActiveRecord::RecordInvalid
      false
    end

    # `record` is now the preferred name
    singleton_class.send :alias_method, :record, :create_event

    def queue_triggers
      if (actions = TRIGGERS[kind])
        actions.each do |action|
          SibylTriggerWorker.perform_async(action.to_s, kind, id)
        end
      end
    end

    def self.filter_property?(as = nil, property)
      if property.blank?
        all
      else
        properties = property_array(property)

        query = ""
        properties.each_with_index do |property, i|
          # data?'foo' AND data->'foo'?'bar' AND data->'foo'->'bar'?'baz'
          query += " AND " unless i == 0
          query += "#{as}#{'.' if as}data"
          query += "->" unless properties[0...i].empty?
          query += properties[0...i].join("->")
          query += "?#{property}"
        end

        where(query)
      end
    end

    def self.filter_property_value(as = nil, filter, property, value)
      if property.blank? || value.blank?
        all
      else
        property = property_query(as, property)

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
                end

        puts query
        where(query)
      end
    end

    def self.group_by(as = nil, property, order)
      order = order.blank? ? "DESC" : order
      property = property_query(as, property)

      reorder("(#{property})::text #{order}")
        .group("(#{property})::text")
    end

    def self.operation(as = nil, op, property, order, primitive: true)
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
          sc.select("DISTINCT COUNT(DISTINCT (#{property})::text)")
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

    def self.order_by(as = nil, order)
      order = safe_order(order)
      @danger_order = true

      order("#{as}#{'.' if as}occurred_at #{order.to_sym}")
    end

    def self.in_kind(as = nil, kind)
      if kind.blank?
        all
      else
        kind = kind.split(",").map(&:strip)
        where("#{as}#{"." if as}kind": kind) # WHERE kind IN ('foo', 'bar')
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

    def self.property_query(as = nil, property)
      unless property.blank?
        "#{as}#{'.' if as}data->#{property_array(property).join('->')}"
      end
    end

    def self.safe_order(order)
      order.blank? || order == "desc" ? "DESC" : order
    end

    def self.safe_op(op, primitive)
      sc = where(nil)
      sc = sc.reorder("") if @danger_order
      sc = yield(sc)
      if primitive
        sc.inspect # this is needed to kick AR into action
        if sc.size == 1
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

    # def self.where_funnel(property, last_property, relation)
      # relation = relation.filter_property?(last_property)
      # relation = relation.select(property_query(last_property))

      # filter_property?(property).where("#{property_query(property)} IN (#{relation.to_sql})")
    # end

    def self.where_funnel(i, property, last_property, relation, period_to)
      p property
      p last_property
      relation = relation.filter_property?("a#{i - 1}", last_property)
                         .select("MIN(a#{i - 1}.occurred_at) AS occurred_at, #{property_query("a#{i - 1}", last_property)} AS jid")
      relation = relation.group(property_query("a#{i - 1}", last_property)).reorder("")

      new_rel = from("sibyl_events AS a#{i}")
                .filter_property?("a#{i}", property)
                .joins("INNER JOIN (#{relation.to_sql}) o#{i} ON o#{i}.jid = #{property_query("a#{i}", property)}")
      new_rel = new_rel.where("a#{i}.occurred_at >= o#{i}.occurred_at")
      new_rel = new_rel.where("a#{i}.occurred_at <= (o#{i}.occurred_at + INTERVAL ?)", period_to) unless period_to.blank?
      new_rel
    end
  end
end
