require 'sidekiq'

class ProcessCSVJob
  include Sidekiq::Worker
  sidekiq_options queue: 'medium', retry: 0

  def perform(processor_class, payload, key)
    retry_limit = 3
    begin
      BulkProcessor::ProcessCSV.new(
        processor_class.constantize,
        BulkProcessor::PayloadSerializer.deserialize(payload),
        key
      ).perform
    rescue Exception => e
      if retry_limit > 0
        retry_limit -= 1
        retry
      end
      raise e
    ensure
      BulkProcessor.config.file_class.new(key).delete
    end
  end
end
