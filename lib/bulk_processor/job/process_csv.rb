require 'active_job'

class BulkProcessor
  # ActiveJob to handle processing the CSV in the background
  module Job
    class ProcessCSV < ActiveJob::Base
      queue_as 'bulk_processor'

      def perform(processor_class, payload, key)
        file = BulkProcessor.config.file_class.new(key)
        payload = PayloadSerializer.deserialize(payload)
        file.open do |f|
          csv = CSV.parse(f.read, headers: true)
          processor = processor_class.constantize.new(csv, payload: payload)
          processor.start
        end
      ensure
        file.try(:delete)
      end
    end
  end
end
