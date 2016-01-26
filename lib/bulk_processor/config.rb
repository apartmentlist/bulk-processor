class BulkProcessor
  # Store configuration data set by clients
  class Config
    attr_reader :back_end, :queue_adapter
    attr_writer :file_class
    attr_accessor :temp_directory

    def back_end=(back_end)
      require_relative "back_end/#{back_end}"
      @back_end = back_end
    rescue LoadError => error
      puts error.message
      raise ArgumentError, "Invalid back-end: #{back_end}"
    end

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
