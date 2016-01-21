require 'active_job'

class BulkProcessor
  # ActiveJob to handle processing the CSV in the background
  module Job
    class SplitCSV < ActiveJob::Base
      queue_as 'bulk_processor'

      def perform(processor_class, payload, key, num_chunks)
        processor_class = processor_class.constantize
        chunker = row_chunker(processor_class, num_chunks)
        payload = PayloadSerializer.deserialize(payload)
        splitter = FileSplitter.new(key: key, row_chunker: chunker)
        keys = splitter.split!
        keys.each do |key|
          BackEnd.start(processor_class: processor_class, payload: payload, key: key)
        end
      rescue Exception => error
        if processor_class.respond_to?(:handler_class)
          handler = processor_class.handler_class.new(payload: payload, results: [])
          handler.fail!(error)
        end
        raise
      ensure
        BulkProcessor.config.file_class.new(key).delete
      end

      private

      def row_chunker(processor_class, num_chunks)
        if processor_class.respond_to?(:boundary_column)
          boundary_column = processor_class.boundary_column
          RowChunker::Boundary.new(num_chunks, boundary_column: boundary_column)
        else
          RowChunker::Balanced.new(num_chunks)
        end
      end
    end
  end
end
