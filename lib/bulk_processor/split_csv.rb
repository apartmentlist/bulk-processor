class BulkProcessor
  class SplitCSV
    def initialize(processor_class, payload, key, num_chunks)
      @processor_class = processor_class
      @payload = payload
      @key = key
      @num_chunks = num_chunks
    end

    def perform
      splitter = FileSplitter.new(key: key, row_chunker: row_chunker)
      keys = splitter.split!
      keys.each do |key|
        BackEnd.start(processor_class: processor_class, payload: payload, key: key)
      end
    rescue Exception => error
      handle_error(error)
      raise
    end

    private

    attr_reader :processor_class, :payload, :key, :num_chunks

    def row_chunker
      if processor_class.respond_to?(:boundary_column)
        boundary_column = processor_class.boundary_column
        RowChunker::Boundary.new(num_chunks, boundary_column: boundary_column)
      else
        RowChunker::Balanced.new(num_chunks)
      end
    end

    def handle_error(error)
      if processor_class.respond_to?(:handler_class)
        handler = processor_class.handler_class.new(
          payload: payload.merge('key' => key),
          results: []
        )
        handler.fail!(error)
      end
    end
  end
end
