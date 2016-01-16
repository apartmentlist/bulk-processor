class BulkProcessor
  module Role
    # Role used by BulkProcessor::CSVProcessor (itself an abstract
    # implementation of the CSVProcessor role) to report on the results (or
    # failure) of processing a CSV file.
    class Handler
      def initialize(payload:, results:)
      end

      def complete!
      end

      def fail!(fatal_error)
      end
    end
  end
end
