class BulkProcessor
  class ValidatedCSV
    PARSING_OPTIONS  = { headers: true, header_converters: :downcase }
    private_constant :PARSING_OPTIONS

    attr_reader :errors, :records

    def initialize(stream, required_headers, optional_headers)
      @stream = stream
      @required_headers = required_headers
      @optional_headers = optional_headers
      @errors = []
    end

    def valid?
      @errors = []

      if missing_headers.any?
        errors << "Missing required column(s): #{missing_headers.join(', ')}"
      end

      if extra_headers.any?
        errors << "Unrecognized column(s) found: #{extra_headers.join(', ')}"
      end

      unless csv.headers.all?
        errors << 'Missing or malformed column header, is one of them blank?'
      end
      errors.empty?
    end

    def row_hashes
      csv.map(&:to_hash)
    end

    private

    attr_reader :stream, :required_headers, :optional_headers

    def csv
      @csv ||= CSV.parse(stream, PARSING_OPTIONS)
    end

    def missing_headers
      required_headers - csv.headers
    end

    def extra_headers
      csv.headers - [*required_headers, *optional_headers]
    end
  end
end
