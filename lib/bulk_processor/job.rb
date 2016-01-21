require 'active_job'

class BulkProcessor
  # ActiveJob to handle processing the CSV in the background
  class Job < ActiveJob::Base
    queue_as 'bulk_processor'

    def perform(processor_class, payload, file_class, key)
      file = file_class.constantize.new(key)
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
