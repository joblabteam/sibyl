module Sibyl
  class TriggerAction
    attr_reader :call_class, :delay

    def initialize(call_class, **options)
      @call_class = call_class.to_s
      @delay = options.delete(:delay)
      @delay = @delay.to_i if @delay&.respond_to?(:to_i)
      @options = options # not currently used or exposed
    end

    def delayed?
      @delay != nil
    end
  end
end
