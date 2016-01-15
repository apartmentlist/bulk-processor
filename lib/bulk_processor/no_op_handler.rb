class BulkProcessor
  class NoOpHandler
    def initialize(payload:, successes:, errors:)
    end

    def complete!
    end

    def fail!(fatal_error)
    end
  end
end
