class MockItemProcessor
  cattr_writer :required_columns, :optional_columns
  attr_reader :record, :messages

  def self.required_columns
    @@required_columns || []
  end

  def self.optional_columns
    @@optional_columns || []
  end

  def initialize(record, _payload)
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
