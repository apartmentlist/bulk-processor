class BulkProcessor
  class CSVProcessor
    # An abstract implementation of the RowProcessor role
    class RowProcessor
      PRIMARY_KEY_ROW_NUM = '_row_num'.freeze

      def initialize(row, payload:)
        @row = row
        @payload = payload
        @successful = false
        @messages = []
      end

      def process!
        raise NotImplementedError,
              "#{self.class.name} must implement #{__method__}"
      end

      def result
        Result.new(messages: messages, row_num: row[PRIMARY_KEY_ROW_NUM],
                   primary_attributes: primary_attrs, successful: @successful)
      end

      private

      attr_reader :row, :payload, :messages
      attr_writer :successful

      # Override this with an array of column names that can be used to uniquely
      # identify a row, if you'd prefer to not identify rows by row number
      def primary_keys
        []
      end

      # @return [Hash<String, String>] the set of primary keys and their values
      #   for this row
      def primary_attrs
        row.slice(*primary_keys)
      end
    end
  end
end
