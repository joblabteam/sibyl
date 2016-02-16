module Sibyl
  class Event < ActiveRecord::Base
    def self.create_event(kind, occurred_at = Time.now, data)
      event = create!(
        kind: kind,
        occurred_at: occurred_at,
        data: data
      )

      if (actions = TRIGGERS[kind])
        actions.each do |action|
          TriggerWorker.perform_async(action.to_s, kind, event.id)
        end
      end
    rescue ActiveRecord::RecordInvalid
      false
    end

    def self.filter_property?(property)
      if property.blank?
        all
      else
        properties = property_array(property)

        query = ""
        properties.each_with_index do |property, i|
          # data?'foo' AND data->'foo'?'bar' AND data->'foo'->'bar'?'baz'
          query += " AND " unless i == 0
          query += "data"
          query += "->" unless properties[0...i].empty?
          query += properties[0...i].join("->")
          query += "?#{property}"
        end

        where(query)
      end
    end

    def self.filter_property_value(filter, property, value)
      if property.blank? || value.blank?
        all
      else
        property = property_query(property)

        case filter.to_s
        when "eq"
          query = "(#{property})::text = '#{value}'"
        when "ne"
          query = "(#{property})::text != '#{value}'"
        when "lt"
          query = "(#{property})::text::float < #{value}"
        when "lte"
          query = "(#{property})::text::float <= #{value}"
        when "gt"
          query = "(#{property})::text::float > #{value}"
        when "gte"
          query = "(#{property})::text::float >= #{value}"
        else # contains
          query += " @> '#{value}'::jsonb"
        end

        puts query
        where(query)
      end
    end

    def self.group_by(property, order)
      order = order.blank? ? "DESC" : order
      property = property_query(property)

      reorder("(#{property})::text #{order}")
        .group("(#{property})::text")
    end

    def self.operation(op, property, order)
      order = order.blank? ? "DESC" : order
      property = property_query(property)

      case op
      when "count"
        # count
        reorder("").select("COUNT(*)")# [0][:count]
      when "uniq"
        # reorder("").distinct.count("(#{property})::text")
        reorder("").select("DISTINCT COUNT(DISTINCT (#{property})::text)")[0][:count]
      when "group"
        reorder("(#{property})::text #{order}")
          .group("(#{property})::text").count # ("(#{property})::text")
      when "min"
        reorder("").select("MIN((#{property})::text::float)")[0][:min]
      when "max"
        reorder("").select("MAX((#{property})::text::float)")[0][:max]
      when "avg"
        reorder("").select("AVG((#{property})::text::float)")[0][:avg]
      when "sum"
        reorder("").select("SUM((#{property})::text::float)")[0][:sum]
      else
        all
      end
    end

    def self.interval(interval)
      # WARNING POTENTIAL FOR SQL INJECTION BELOW!!!
      if %w(second minute hour day week month quarter year).include? interval
        select("date_trunc('#{interval}', occurred_at) AS \"interval\"")
          .reorder('"interval"')
          .group('"interval"')
      end
    end

    def self.order_by(order)
      if order.blank?
        order(occurred_at: :desc)
      else
        order(occurred_at: order.to_sym)
      end
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

    def self.property_array(property)
      property.split(",").map { |p| "'#{p.strip}'" } unless property.blank?
    end

    def self.property_query(property)
      "data->#{property_array(property).join('->')}" unless property.blank?
    end
  end
end
