require 'active_job'
require 'csv'

require 'bulk_processor/config'
require 'bulk_processor/job'
require 'bulk_processor/stream_encoder'
require 'bulk_processor/validated_csv'
require 'bulk_processor/version'

class BulkProcessor
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end

  end

  attr_reader :stream, :item_processor, :handler, :payload, :errors

  def initialize(stream, item_processor, handler, payload = {})
    @stream = stream
    @item_processor = item_processor
    @handler = handler
    @payload = payload
    @errors = []
  end

  def process
    csv = ValidatedCSV.new(
      StreamEncoder.new(stream).encoded,
      item_processor.required_columns,
      item_processor.optional_columns
    )

    if csv.valid?
      Job.perform_later(csv.row_hashes, item_processor.to_s, handler.to_s, payload)
    else
      @errors = csv.errors
    end
    @errors.empty?
  end
end
