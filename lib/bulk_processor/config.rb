class BulkProcessor
  # Store configuration data set by clients
  class Config
    attr_reader :queue_adapter
    attr_accessor :temp_directory

    def queue_adapter=(adapter)
      ActiveJob::Base.queue_adapter = @queue_adapter = adapter
    end

    def aws
      @aws ||= Struct.new(:access_key_id, :secret_access_key, :bucket).new
    end
  end
end
