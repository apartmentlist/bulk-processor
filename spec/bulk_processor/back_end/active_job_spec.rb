describe BulkProcessor::BackEnd::ActiveJob do
  describe '#start' do
    subject do
      BulkProcessor::BackEnd::ActiveJob.new(
        processor_class: MockCSVProcessor,
        payload: {},
        file_class: MockFile,
        key: 'file.csv'
      )
    end

    it 'enqueues an ActiveJob' do
      expect(BulkProcessor::Job).to receive(:perform_later)
        .with('MockCSVProcessor', '{}', 'MockFile', 'file.csv')
      subject.start
    end
  end
end
