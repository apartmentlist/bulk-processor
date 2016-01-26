class BulkProcessor
  module BackEnd
    class ActiveJob
      # ActiveJob to handle processing the CSV in the background
      class SplitCSVJob < ::ActiveJob::Base
        queue_as 'bulk_processor'

        def perform(processor_class, payload, key, num_chunks)
          BulkProcessor::SplitCSV.new(
            processor_class.constantize,
            PayloadSerializer.deserialize(payload),
            key,
            num_chunks
          ).perform
        end
      end
    end
  end
end
