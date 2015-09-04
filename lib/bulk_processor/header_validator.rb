class BulkProcessor
  class HeaderValidator
    attr_reader :headers, :required_headers, :optional_headers, :errors

    def initialize(headers, required_headers, optional_headers)
      @headers = headers
      @required_headers = required_headers
      @optional_headers = optional_headers
      @errors = []
    end

    def valid?
      @errors = []
      missing_headers = required_headers - headers
      if missing_headers.any?
        errors << "Missing required column(s): #{missing_headers.join(', ')}"
      end

      extra_headers = headers - [*required_headers, *optional_headers]
      if extra_headers.any?
        errors << "Unrecognized column(s) found: #{extra_headers.join(', ')}"
      end

      if headers.any?(&:nil?)
        errors << 'Missing or malformed column header'
      end

      errors.empty?
    end
  end
end
