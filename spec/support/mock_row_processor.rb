class MockRowProcessor
  attr_reader :record, :messages

  def initialize(record, payload:)
    @record = record
    @success = false
    @messages = []
  end

  def process!
    case record['name']
    when 'Rex'
      @success = true
    when 'Human'
      raise 'bad human'
    else
      @success = false
      @messages << 'bad dog'
    end
  end

  def success?
    @success
  end
end
