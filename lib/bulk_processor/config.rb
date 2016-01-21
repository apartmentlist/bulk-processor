class BulkProcessor
  # Store configuration data set by clients
  class Config
    attr_reader :queue_adapter
    attr_writer :file_class
    attr_accessor :back_end, :temp_directory

    def queue_adapter=(adapter)
      ActiveJob::Base.queue_adapter = @queue_adapter = adapter
    end

    def file_class
      @file_class || BulkProcessor::S3File
    end

    def aws
      @aws ||= Struct.new(:access_key_id, :secret_access_key, :bucket).new
    end

    def heroku
      @heroku ||= Struct.new(:api_key, :app_name).new
    end
  end
end
