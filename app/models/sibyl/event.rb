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
  end
end
