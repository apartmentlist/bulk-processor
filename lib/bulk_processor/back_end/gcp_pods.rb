require 'gcp_job_manager'

class BulkProcessor
  module BackEnd
    class GcpPods
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class.name
        @payload = PayloadSerializer.serialize(payload)
        @key = key
      end

      def start
        args = [processor_class, payload, key]
        GcpJobManager.create_and_deploy_job('start-bulk-processor', args)
      end

      def split(num_processes)
        args = [processor_class, payload, key, num_processes.to_s]
        GcpJobManager.create_and_deploy_job('split-bulk-processor', args)
      end

      private

      attr_reader :processor_class, :payload, :key
    end
  end
end