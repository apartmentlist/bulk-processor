require 'gcp_manager'

class BulkProcessor
  module BackEnd
    class Gcp
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class.name
        @payload = PayloadSerializer.serialize(payload)
        @key = key

        GcpManager.add_task('start-bulk-processor', 'bundle exec rake bulk_processor_gcp_pods:start')
        GcpManager.add_task('split-bulk-processor', 'bundle exec rake bulk_processor_gcp_pods:split')
      end

      def start
        args = [processor_class, payload, key]
        GcpManager.create_and_deploy_job('start-bulk-processor', args)
      end

      def split(num_processes)
        args = [processor_class, payload, key, num_processes.to_s]
        GcpManager.create_and_deploy_job('split-bulk-processor', args)
      end

      private

      attr_reader :processor_class, :payload, :key
    end
  end
end