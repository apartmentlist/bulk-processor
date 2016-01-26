require 'active_job'

require_relative 'active_job/process_csv_job'
require_relative 'active_job/split_csv_job'

class BulkProcessor
  module BackEnd
    # Execute jobs via ActiveJob, e.g. Resque
    class ActiveJob
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class.name
        @payload = PayloadSerializer.serialize(payload)
        @key = key
      end

      def start
        ActiveJob::ProcessCSVJob.perform_later(processor_class, payload, key)
      end

      def split(num_processes)
        ActiveJob::SplitCSVJob.perform_later(processor_class, payload, key,
                                             num_processes)
      end

      private

      attr_reader :processor_class, :payload, :key
    end
  end
end
