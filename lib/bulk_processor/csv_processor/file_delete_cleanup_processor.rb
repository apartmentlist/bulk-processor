class BulkProcessor
  class CSVProcessor
    # A File delete object implementation of the PostProcessor role
    class FileDeleteCleanupProcessor
      def initialize(row_processors)
      end

      def start
        BulkProcessor.config.file_class.new(key).delete
      end
    end
  end
end
