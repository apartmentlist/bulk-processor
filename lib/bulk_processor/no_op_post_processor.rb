class BulkProcessor
  # A null object implementation of the PostProcessor role
  class NoOpPostProcessor
    def initialize(row_processors)
    end

    def start
    end
  end
end
