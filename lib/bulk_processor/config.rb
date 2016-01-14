class BulkProcessor
  # Store configuration data set by clients
  class Config
    attr_reader :queue_adapter

    def queue_adapter=(adapter)
      ActiveJob::Base.queue_adapter = @queue_adapter = adapter
    end
  end
end
