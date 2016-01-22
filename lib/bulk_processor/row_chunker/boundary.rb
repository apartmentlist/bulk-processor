class BulkProcessor
  module RowChunker
    # Determine the partitions that ensure all consecutive rows with the same
    # value for boundary_column are in the same partion. The CSV must be sorted
    # on this column to get the desired results. This class makes an attempt to
    # keep the partion sizes equal, but obviously prioritizes the boundary
    # column values over partition size.
    class Boundary
      def initialize(num_chunks, boundary_column:)
        @num_chunks = num_chunks
        @boundary_column = boundary_column
      end

      def ranges_for(csv)
        @ranges ||= begin
          # Start with a balanced partition, then make adjustments from there
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
