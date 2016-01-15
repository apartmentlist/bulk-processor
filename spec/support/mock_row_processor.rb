class MockRowProcessor
  attr_reader :messages

  def initialize(record, payload:)
  end

  def process!
  end

  def success?
  end
end
