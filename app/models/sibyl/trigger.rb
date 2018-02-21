module Sibyl
  class Trigger
    def initialize(sibyl = Sibyl::Event)
      @sibyl = sibyl
    end

    def self.trigger_map(trigs)
      Hash[trigs.map { |v| [v, self] }]
    end

    # Load the trigger class into the list of triggers
    def self.triggers(*trigs, **options)
      trigger_map(trigs).each do |trigger, action|
        trigger_action = TriggerAction.new(action, **options)
        TRIGGERS[trigger] = Array(TRIGGERS[trigger]) << trigger_action
      end
    end

    protected

    def route_helpers
      Rails.application.routes.url_helpers
    end
  end
end
