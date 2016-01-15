class BulkProcessor
  module Role
    class RowProcessor
      def initialize(record, payload: payload)
      end

      def process!
      end

      def success?
      end

      def messages
      end
    end
  end
end
