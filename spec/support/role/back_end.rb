class BulkProcessor
  module Role
    class BackEnd
      def initialize(processor_class:, payload:, key:)
      end

      def start
      end

      def split(num_processes)
      end
    end
  end
end
