require 'bulk_processor/back_end'
require 'bulk_processor/config'
require 'bulk_processor/file_splitter'
require 'bulk_processor/payload_serializer'
require 'bulk_processor/process_csv'
require 'bulk_processor/row_chunker/balanced'
require 'bulk_processor/row_chunker/boundary'
require 'bulk_processor/s3_file'
require 'bulk_processor/split_csv'
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
  def start(num_processes = 1)
    if BulkProcessor.config.file_class.new(key).exists?
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
      start_backend(encoded_contents, num_processes)
    else
      errors.concat(csv.errors)
    end
    errors.empty?
  end

  private

  attr_reader :key, :stream, :processor_class, :payload

  def start_backend(contents, num_processes)
    file = BulkProcessor.config.file_class.new(key)
    file.write(contents)
    BackEnd.start(processor_class: processor_class, payload: payload, key: key,
                  num_processes: num_processes)
  rescue Exception
    # Clean up the file, which is treated as a lock, if we bail out of here
    # unexpectedly.
    file.try(:delete)
    raise
  end
end
