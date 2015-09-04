class BulkProcessor
  class Job < ActiveJob::Base
    queue_as 'bulk_processor'

    def perform(records, item_proccessor, handler, payload)
      item_proccessor_class = item_proccessor.constantize
      handler_class = handler.constantize

      successes = {}
      failures = {}
      records.each_with_index do |record, index|
        processor = item_proccessor_class.new(record)
        processor.process!
        if processor.success?
          successes[index] = processor.messages
        else
          failures[index] = processor.messages
        end
      end
      handler_class.complete(payload, successes, failures, nil)
    rescue => error
      handler_class.complete(payload, successes, failures, error)
    end
  end
end
