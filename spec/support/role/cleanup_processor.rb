class BulkProcessor
  module Role
    # Role used by BulkProcessor::CSVProcessor (itself an abstract
    # implementation of the CSVProcessor role) to do any additional processing
    # on the entire CSV (or any subset of it) after every row has been processed
    class CleanupProcessor
      def initialize(payload)
      end

      def start
      end
    end
  end
end
