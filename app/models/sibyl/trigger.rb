module Sibyl
  class Trigger # < ActiveRecord::Base
    private

    def self.trigger_map(trigs)
      Hash[trigs.map { |v| [v, self] }]
    end

    # Load the trigger class into the list of triggers
    def self.triggers(*trigs)
      trigger_map(trigs).each do |trigger, action|
        TRIGGERS[trigger] = Array(TRIGGERS[trigger]) << action
      end
    end
  end
end
