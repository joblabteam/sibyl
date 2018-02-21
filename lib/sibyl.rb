require "sibyl/engine"
require "csv"

module Sibyl
  # TRIGGERS is a hash of event names to arrays of triggers
  # E.g.
  #   {
  #     "test-event" => [
  #       TriggerAction.new(TestTrigger),
  #       TriggerAction.new(AnotherTrigger, delay: 1.hour)
  #     ]
  #   }
  TRIGGERS = {} # rubocop:disable Style/MutableConstant # do not freeze!
end
