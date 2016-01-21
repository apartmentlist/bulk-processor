class BulkProcessor
  module RowChunker
    class Boundary
      def initialize(num_chunks, boundary_column:)
        @num_chunks = num_chunks
        @boundary_column = boundary_column
      end

      def ranges_for(csv)
        @ranges ||= begin
          chunker = Balanced.new(num_chunks)
          adjust_for_boundaries(chunker.ranges_for(csv), csv)
        end
      end

      private

      attr_reader :num_chunks, :boundary_column

      def adjust_for_boundaries(balanced_ranges, csv)
        balanced_endings = balanced_ranges.map(&:last)

        last_indexes = []
        while balanced_endings.any?
          last_index = [last_indexes.last, balanced_endings.shift].compact.max
          last_index += 1 until at_boundary?(csv, last_index)
          last_indexes << last_index
        end

        to_ranges(last_indexes)
      end

      def to_ranges(last_indexes)
        first_indexes = last_indexes.dup
        first_indexes.pop
        first_indexes.map! { |index| index + 1 }
        first_indexes.unshift(0)
        first_indexes.map.with_index do |first_index, index|
          (first_index..last_indexes[index])
        end
      end

      def at_boundary?(csv, index)
        return true if index == csv.count - 1
        csv[index][boundary_column] != csv[index + 1][boundary_column]
      end
    end
  end
end
