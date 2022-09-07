class MockPreProcessor
  def initialize(row_processors)
  end

  def start
  end

  def results
    []
  end

  def self.fail_process_if_failed
    true
  end
end
