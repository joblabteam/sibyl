class SibylTriggerWorker
  include Sidekiq::Worker

  def perform(action_s, kind, event_id)
    action = action_s.constantize
    event = Sibyl::Event.find(event_id)
    action.new(Sibyl::Event).call(kind, event)
  end
end
