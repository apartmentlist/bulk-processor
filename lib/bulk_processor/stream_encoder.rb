class BulkProcessor
  # Force encode a stream into UTF-8 by removing invalid and undefined
  # characters.
  class StreamEncoder
    ENCODING_OPTIONS = { undef: :replace, invalid: :replace, replace: '' }.freeze
    private_constant :ENCODING_OPTIONS

    def initialize(stream)
      @stream = stream
    end

    # Return the UTF-8 encoded string.
    #
    # Note: this method reads the stream, so it will need to be rewound before
    # attempting to read again.
    #
    # @return [String] a UTF-8 encoded string
    def encoded
      stream.read.encode(Encoding::UTF_8, **ENCODING_OPTIONS)
    end

    private

    attr_reader :stream
  end
end
