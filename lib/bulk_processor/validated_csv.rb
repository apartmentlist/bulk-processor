require 'csv'

class BulkProcessor
  # A Wrapper on CSV that validates column headers.
  class ValidatedCSV
    PARSING_OPTIONS  = { headers: true, header_converters: :downcase }
    private_constant :PARSING_OPTIONS

    # This cryptic message usually just means that the header row contains a
    # blank field; in ruby ~> 2.1.5 It is the error message for a NoMethodError
    # raised when parsing a CSV.
    BAD_HEADERS_ERROR_MSG = "undefined method `encode' for nil:NilClass"
    private_constant :BAD_HEADERS_ERROR_MSG

    MISSING_COLUMN_MESSAGE = 'Missing or malformed column header, is one of them blank?'
    private_constant :MISSING_COLUMN_MESSAGE

    attr_reader :errors, :records

    def initialize(stream, required_headers, optional_headers)
      @stream = stream
      @required_headers = required_headers
      @optional_headers = optional_headers
      @errors = []
    end

    # @return [true|false] true iff:
    #   * All required columns are present
    #   * No column exists that isn't a required or optional column
    #   * No column heading is blank
    def valid?
      return false if csv.nil?
      @errors = []

      if missing_headers.any?
        errors << "Missing required column(s): #{missing_headers.join(', ')}"
      end

      if extra_headers.any?
        errors << "Unrecognized column(s) found: #{extra_headers.join(', ')}"
      end

      if csv.headers.any? { |header| header.nil? || header.strip == '' }
        errors << MISSING_COLUMN_MESSAGE
      end

      errors.empty?
    end

    # @return [Array<Hash<String, String>>] a serializable representation of the
    #   CSV that will be passed to the background job.
    def row_hashes
      return [] unless valid?
      csv.map(&:to_hash)
    end

    private

    attr_reader :stream, :required_headers, :optional_headers

    def csv
      return @csv if instance_variable_defined?('@csv')
      @csv = CSV.parse(stream, PARSING_OPTIONS)
    rescue NoMethodError => error
      if error.message == BAD_HEADERS_ERROR_MSG
        errors << MISSING_COLUMN_MESSAGE
        @csv = nil
      else
        raise error
      end
    end

    def missing_headers
      required_headers - csv.headers
    end

    def extra_headers
      csv.headers - [*required_headers, *optional_headers]
    end
  end
end
