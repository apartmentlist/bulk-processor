require 'bulk_processor/csv_processor'

class MockCSVProcessor < BulkProcessor::CSVProcessor
  def self.required_columns
    []
  end

  def self.row_processor_class
    MockRowProcessor
  end

  def self.handler_class
    MockHandler
  end
end
