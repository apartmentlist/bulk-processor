class BulkProcessor
  class CSVProcessor
    # A null object implementation of the PostProcessor role
    class NoOpCleanupProcessor
      def initialize(row_processors)
      end

      def start
      end
    end
  end
end
