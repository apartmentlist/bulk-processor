class BulkProcessor
  class CSVProcessor
    # A null object implementation of the PreProcessor role
    class NoOpPreProcessor
      def initialize(row_processors)
      end

      def start
      end

      def results
        []
      end

      def self.fail_process_if_failed
        false
      end
    end
  end
end
