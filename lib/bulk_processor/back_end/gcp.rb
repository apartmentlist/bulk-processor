# frozen_string_literal: true

require 'gcp_manager'

class BulkProcessor
  module BackEnd
    class Gcp
      def initialize(processor_class:, payload:, key:, job:)
        @processor_class = processor_class.name
        @payload = PayloadSerializer.serialize(payload)
        @job = job
        @key = key
      end

      def start
        args = [processor_class, payload, key]
        GcpManager.create_and_deploy_job(job, args)
      end

      def split(num_processes)
        args = [processor_class, payload, key, num_processes.to_s]
        GcpManager.create_and_deploy_job('split-bulk-processor', args)
      end

      private

      attr_reader :processor_class, :payload, :key, :job
    end
  end
end
