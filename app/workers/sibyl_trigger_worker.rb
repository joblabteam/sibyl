class SibylTriggerWorker
  include Sidekiq::Worker

  def perform(call_class, kind, event_id)
    cls = call_class.constantize
    event = Sibyl::Event.find(event_id)
    cls.new.call(kind, event)
  end
end
