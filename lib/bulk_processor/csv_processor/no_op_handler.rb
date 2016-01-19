class BulkProcessor
  class CSVProcessor
    # A null object implementation of the Handler role
    class NoOpHandler
      def initialize(payload:, results:)
      end

      def complete!
      end

      def fail!(fatal_error)
      end
    end
  end
end
