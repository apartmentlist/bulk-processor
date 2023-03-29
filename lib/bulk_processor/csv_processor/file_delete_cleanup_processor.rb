class BulkProcessor
  class CSVProcessor
    # A File delete object implementation of the Cleanup role
    class FileDeleteCleanupProcessor
      attr_reader :payload

      def initialize(payload)
        @payload = payload
      end

      def start
        BulkProcessor.config.file_class.new(payload['key']).delete
      end
    end
  end
end
