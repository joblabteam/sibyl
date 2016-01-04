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

    def self.target_property?(properties)
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

    def self.target_property_value(properties, value)
      if properties.blank? || value.blank?
        all
      else
        properties = properties.split(",").map { |p| "'#{p.strip}'" }

        query = "data->#{properties.join("->")}"
        query += " @> '#{value}'::jsonb"

        puts query
        where(query)
      end
    end
  end
end
