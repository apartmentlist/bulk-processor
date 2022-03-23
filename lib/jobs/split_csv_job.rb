require 'sidekiq'

class SplitCSVJob
  include Sidekiq::Worker
  sidekiq_options queue: 'medium'

  def perform(processor_class, payload, key, num_chunks)
    BulkProcessor::SplitCSV.new(
      processor_class.constantize,
      BulkProcessor::PayloadSerializer.deserialize(payload),
      key,
      num_chunks
    ).perform
  end
end
