class BulkProcessor
  class ProcessCSV
    def initialize(processor_class, payload, key)
      @processor_class = processor_class
      @payload = payload
      @key = key
    end

    def perform
      file = BulkProcessor.config.file_class.new(key)
      file.open do |f|
        csv = CSV.parse(f.read, headers: true)
        processor = processor_class.new(csv, payload: payload.merge('key' => key))
        processor.start
      end
    ensure
      file.try(:delete)
    end

    private

    attr_reader :processor_class, :payload, :key
  end
end
