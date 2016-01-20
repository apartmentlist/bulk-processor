require 'bulk_processor/config'
require 'bulk_processor/job'
require 'bulk_processor/s3_file'
require 'bulk_processor/stream_encoder'
require 'bulk_processor/validated_csv'
require 'bulk_processor/version'

# Process large CSV files in the background.
class BulkProcessor
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end
  end

  attr_reader :errors

  def initialize(stream:, processor_class:, payload: {})
    @stream = stream
    @processor_class = processor_class
    @payload = payload
    @errors = []
  end

  # Validate the CSV and enqueue if for processing in the background.
  def start
    csv = ValidatedCSV.new(
      StreamEncoder.new(stream).encoded,
      processor_class.required_columns,
      processor_class.optional_columns
    )

    if csv.valid?
      Job.perform_later(csv.row_hashes, processor_class.name, payload)
    else
      @errors = csv.errors
    end
    @errors.empty?
  end

  private

  attr_reader :stream, :processor_class, :payload
end
