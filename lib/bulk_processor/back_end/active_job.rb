class BulkProcessor
  module BackEnd
    class ActiveJob
      def initialize(processor_class:, payload:, file_class:, key:)
        @processor_class = processor_class
        @payload = payload
        @file_class = file_class
        @key = key
      end

      def start
        Job.perform_later(processor_class.name, payload.to_json, file_class.name, key)
      end

      private

      attr_reader :processor_class, :payload, :file_class, :key
    end
  end
end
