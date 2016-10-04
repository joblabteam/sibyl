module Sibyl
  class Action < Event
    OPERATORS = { gte: :>=, gt: :>, lte: :<=, lt: :<, eq: :== }.freeze

    # @param kind: String name of action (event is prepended with sibyl-action_)
    # @param user: String or Integer or object responding to `id`
    # @param with: (optional) extra data responding to `to_json`
    #                         preferably String or Integer
    # @param meta: (optional) extra meta info responding to `to_json`
    #                         preferably hash, e.g. page, UTM, etc.
    def self.record(kind, user:, with: nil, meta: {})
      user = user.id unless user.is_a?(Integer) || user.is_a?(String)
      Event.record("sibyl-action_#{kind}", user: user, with: with, meta: meta)
    end

    # @param kind can be a string or array of strings
    # @param user: String or Integer or object responding to `id`
    # @param with: (optional) extra data responding to `to_json`
    #                         preferably String or Integer
    # @param _times hash parameter wher key is operator and value is amount
    #               e.g. default is: `gte: 1`. Can be: gte gt eq lt lte
    # @returns: false if times condition not matched, actual count if matched
    def self.occurred?(kind, user:, with: nil, **times)
      kind = Array(kind).map { |k| "sibyl-action_#{k}" }
      kind = kind.first if kind.size == 1

      user = user.id unless user.is_a?(Integer) || user.is_a?(String)

      operator = (times.keys & OPERATORS.keys).first || :gte
      amount = times[operator] || 1

      rel = Event.where(kind: kind)
                 .where("data->'user' = '#{user.to_json}'")
      rel = rel.where("data->'with' = '#{with.to_json}'") if with

      size = rel.size
      size.send(OPERATORS[operator], amount) ? size : false
    end
  end
end
