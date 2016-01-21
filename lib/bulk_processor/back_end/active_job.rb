class BulkProcessor
  module BackEnd
    # Execute jobs via ActiveJob, e.g. Resque
    class ActiveJob
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class
        @payload = payload
        @key = key
      end

      def start
        Job::ProcessCSV.perform_later(processor_class.name, payload, key)
      end

      def split(num_processes)
        Job::SplitCSV.perform_later(processor_class.name, payload,
                                    key, num_processes)
      end

      private

      attr_reader :processor_class, :payload, :key
    end
  end
end
