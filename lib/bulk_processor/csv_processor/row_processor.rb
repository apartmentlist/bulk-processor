class BulkProcessor
  class CSVProcessor
    # An abstract implementation of the RowProcessor role. This class implements
    # `#results` by returning an array of `Results`. To subclass, just implement
    # `#process` to handle the row.
    #
    # The row will be considered a failure by default. After a row is successfully
    # processed, set `self.successful = true`. If there are any messages that
    # should be passed back to the Handler, add them to the `#errors` array.
    #
    # You can optionally override `#primary_keys` so that the result returned
    # has more natural identifiers than just the row number. For example, you
    # setting this to ['species', 'name'] (for the PetRowProcessor example from
    # the README), the result would have `#primary_attributes` like
    #
    #  { 'species' => 'dog', 'name' => 'Fido' }
    #
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
