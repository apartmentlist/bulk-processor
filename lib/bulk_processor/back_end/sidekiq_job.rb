require_relative '../../../lib/jobs/process_csv_job'
require_relative '../../../lib/jobs/split_csv_job'

class BulkProcessor
  module BackEnd
    # Execute jobs via Sidekiq
    class SidekiqJob
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class.name
        @payload = PayloadSerializer.serialize(payload)
        @key = key
      end

      def start
        ProcessCSVJob.perform_async(processor_class, payload, key)
      end

      def split(num_processes)
        SplitCSVJob.perform_async(processor_class, payload, key,
                                             num_processes)
      end

      private

      attr_reader :processor_class, :payload, :key
    end
  end
end
