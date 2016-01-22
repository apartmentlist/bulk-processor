class BulkProcessor
  module RowChunker
    # Determine the partitions for a balanced break up of the input CSV file.
    # All partitions will have a size within 1 row of every other partition.
    class Balanced
      def initialize(num_chunks)
        @num_chunks = num_chunks
      end

      def ranges_for(csv)
        ideal_size = csv.count / num_chunks
        num_chunks.times.map do |index|
          start_index = index * ideal_size
          if index == num_chunks - 1
            # force the last chunk to go to the very last row
            end_index = csv.count - 1
          else
            end_index = start_index + ideal_size - 1
          end
          (start_index..end_index)
        end
      end

      private

      attr_reader :num_chunks
    end
  end
end
