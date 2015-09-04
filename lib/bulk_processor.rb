require 'active_job'
require 'csv'

require 'bulk_processor/config'
require 'bulk_processor/header_validator'
require 'bulk_processor/job'
require 'bulk_processor/version'

module BulkProcessor
  PARSING_OPTIONS  = { headers: true, header_converters: :downcase }
  ENCODING_OPTIONS = { undef: :replace, invalid: :replace, replace: '' }

  # This cryptic message usually just means that the header row contains a
  # blank field; in ruby <~ 2.1.5 It is the error message for a NoMethodError
  # raised when parsing a CSV.
  BAD_HEADERS_ERROR_MSG = "undefined method `encode' for nil:NilClass"

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end

    def process(stream, item_processor, handler, payload = {})
      encoded = stream.read.encode(Encoding::UTF_8, ENCODING_OPTIONS)
      table = CSV.parse(encoded, PARSING_OPTIONS)
      required_columns = item_processor.required_columns
      optional_columns = item_processor.optional_columns
      validator =
        HeaderValidator.new(table.headers, required_columns, optional_columns)

      if validator.valid?
        records = table.map(&:to_hash)
        Job.perform_later(records, item_processor.to_s, handler.to_s, payload)
      else
        handler.invalid(payload, validator.errors)
      end

    rescue NoMethodError => error
      if error.message == BAD_HEADERS_ERROR_MSG
        handler.invalid(payload, ['Missing or malformed column header'])
      else
        raise error
      end
    end
  end
end
