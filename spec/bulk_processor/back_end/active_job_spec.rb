describe BulkProcessor::BackEnd::ActiveJob do
  describe '#start' do
    subject do
      BulkProcessor::BackEnd::ActiveJob.new(
        processor_class: MockCSVProcessor,
        payload: {},
        key: 'file.csv'
      )
    end

    it 'enqueues an ActiveJob' do
      expect(BulkProcessor::Job).to receive(:perform_later)
        .with('MockCSVProcessor', '{}', 'file.csv')
      subject.start
    end
  end
end
