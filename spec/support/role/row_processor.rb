class BulkProcessor
  module Role
    # Role used by BulkProcessor::CSVProcessor (itself an abstract
    # implementation of the CSVProcessor role) to process an individual CSV row.
    class RowProcessor
      def initialize(row, payload:)
      end

      def process!
      end

      def result
      end
    end
  end
end
