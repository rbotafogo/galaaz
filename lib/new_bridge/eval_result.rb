# frozen_string_literal: true

module NewBridge
  # Success/failure wrapper for asynchronous bridge completions (+eval_r_async+).
  class EvalResult
    attr_reader :value, :error

    def self.success(value)
      new(:ok, value, nil)
    end

    def self.failure(error)
      new(:fail, nil, error)
    end

    def initialize(state, value, error)
      @state = state
      @value = value
      @error = error
    end

    def ok?
      @state == :ok
    end
  end
end
