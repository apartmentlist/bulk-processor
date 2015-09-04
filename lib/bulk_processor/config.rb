module BulkProcessor
  class Config
    attr_reader :queue_adpter

    def queue_adpater=(adapter)
      ActiveJob::Base.queue_adapter = @queue_adpater = adapter
    end
  end
end
