class BulkProcessor
  # Split a CSV file on S3 using the specified chunker
  class FileSplitter
    def initialize(key:, row_chunker:)
      @key = key
      @row_chunker = row_chunker
    end

    # Generate multiple files on S3, composed of chunks of the input file.
    #
    # @return [Array<String>] the S3 keys for each new file
    def split!
      return @keys if instance_variable_defined?('@keys')
      ranges = row_chunker.ranges_for(input_csv)
      @keys = ranges.map.with_index do |range, index|
        chunk_key = key_from_index(index, ranges.count)
        contents = csv_from_range(range)
        BulkProcessor.config.file_class.new(chunk_key).write(contents)
        chunk_key
      end
    end

    private

    attr_reader :key, :row_chunker

    def headers
      input_csv.headers
    end

    def input_csv
      return @input_csv if instance_variable_defined?('@input_csv')
      BulkProcessor.config.file_class.new(key).open do |input_file|
        @input_csv = CSV.parse(input_file, headers: true)
      end
      @input_csv
    end

    def csv_from_range(range)
      return CSV.generate { |csv| csv << headers } if range.count == 0
      CSV.generate(headers: headers, write_headers: true) do |csv|
        range.each { |row_num| csv << input_csv[row_num] }
      end
    end

    def key_from_index(index, total)
      parts = key.split('.')
      if parts.length == 1
        name_part = key
        ext_part = ''
      else
        name_part = parts[0..-2].join('.')
        ext_part = ".#{parts.last}"
      end

      "#{name_part}_#{index + 1}-of-#{total}#{ext_part}"
    end
  end
end
