class BulkProcessor
  module BackEnd
    class ActiveJob
      # ActiveJob to handle processing the CSV in the background
      class ProcessCSVJob < ::ActiveJob::Base
        queue_as 'bulk_processor'

        def perform(processor_class, payload, key)
          BulkProcessor::ProcessCSV.new(
            processor_class.constantize,
            PayloadSerializer.deserialize(payload),
            key
          ).perform
        end
      end
    end
  end
end
