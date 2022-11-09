require 'sidekiq'

class SplitCSVJob
  include Sidekiq::Worker
  sidekiq_options queue: 'medium', retry: 0

  def perform(processor_class, payload, key, num_chunks)
    retry_limit = 3
    begin
      BulkProcessor::SplitCSV.new(
        processor_class.constantize,
        BulkProcessor::PayloadSerializer.deserialize(payload),
        key,
        num_chunks
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
