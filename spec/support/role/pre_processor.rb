class BulkProcessor
  module Role
    # Role used by BulkProcessor::CSVProcessor (itself an abstract
    # implementation of the CSVProcessor role) to do any additional processing
    # on the entire CSV (or any subset of it) before every row has been processed
    class PreProcessor
      def initialize(row_processors)
      end

      def start
      end

      def results
      end

      def self.fail_process_if_failed
        true
      end
    end
  end
end
