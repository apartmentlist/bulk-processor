require 'active_job'

class BulkProcessor
  # ActiveJob to handle processing the CSV in the background
  class Job < ActiveJob::Base
    queue_as 'bulk_processor'

    def perform(records, processor_class, payload)
      processor = processor_class.constantize.new(records, payload: payload)
      processor.start
    end
  end
end
