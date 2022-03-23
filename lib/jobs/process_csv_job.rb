require 'sidekiq'

class ProcessCSVJob
  include Sidekiq::Worker
  sidekiq_options queue: 'medium'

  def perform(processor_class, payload, key)
    BulkProcessor::ProcessCSV.new(
      processor_class.constantize,
      BulkProcessor::PayloadSerializer.deserialize(payload),
      key
    ).perform
  end
end
