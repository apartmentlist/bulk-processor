class BulkProcessor
  class Config
    attr_reader :queue_adapter

    def queue_adpater=(adapter)
      ActiveJob::Base.queue_adapter = @queue_adpater = adapter
    end
  end
end
