class BulkProcessor
  module Role
    # Role used by BulkProcessor::Job to process a set of records from a CSV.
    class CSVProcessor
      def self.required_columns
      end

      def self.optional_columns
      end

      def initialize(csv, payload:)
      end

      def start
      end
    end
  end
end
