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

  def initialize(key:, stream:, processor_class:, payload: {})
    @key = key
    @stream = stream
    @processor_class = processor_class
    @payload = payload
    @errors = []
  end

  # Validate the CSV and enqueue if for processing in the background.
  def start(file_class: S3File)
    if file_class.new(key).exists?
      errors << "Already processing #{key}, please wait for it to finish"
      return false
    end

    encoded_contents = StreamEncoder.new(stream).encoded

    csv = ValidatedCSV.new(
      encoded_contents,
      processor_class.required_columns,
      processor_class.optional_columns
    )

    if csv.valid?
      perform_later(file_class, encoded_contents)
    else
      errors.concat(csv.errors)
    end
    errors.empty?
  end

  private

  attr_reader :key, :stream, :processor_class, :payload

  def perform_later(file_class, contents)
    file = file_class.new(key)
    file.write(contents)
    Job.perform_later(processor_class.name, payload, file_class.name, key)
  rescue Exception
    # Clean up the file, which is treated as a lock, if we bail out of here
    # unexpectedly.
    file.try(:delete)
    raise
  end
end
