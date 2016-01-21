class BulkProcessor
  module BackEnd
    class ActiveJob
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class
        @payload = payload
        @key = key
      end

      def start
        Job.perform_later(
          processor_class.name,
          PayloadSerializer.serialize(payload),
          key
        )
      end

      private

      attr_reader :processor_class, :payload, :key
    end
  end
end
