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

    def self.filter_property?(properties)
      if properties.blank?
        all
      else
        properties = properties.split(",").map { |p| "'#{p.strip}'" }

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

    def self.filter_property_value(filter, properties, value)
      if properties.blank? || value.blank?
        all
      else
        properties = properties.split(",").map { |p| "'#{p.strip}'" }
        query = "data->#{properties.join('->')}"

        case filter.to_s
        when "eq"
          query = "(#{query})::text = '#{value}'"
        when "ne"
          query = "(#{query})::text != '#{value}'"
        when "lt"
          query = "(#{query})::text::float < #{value}"
        when "lte"
          query = "(#{query})::text::float <= #{value}"
        when "gt"
          query = "(#{query})::text::float > #{value}"
        when "gte"
          query = "(#{query})::text::float >= #{value}"
        else # contains
          query += " @> '#{value}'::jsonb"
        end

        puts query
        where(query)
      end
    end

    def self.operation(op, property)
      case op
      when "count"
        count
      else
        all
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
  end
end
