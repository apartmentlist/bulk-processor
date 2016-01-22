describe BulkProcessor::BackEnd::ActiveJob do
  it_behaves_like 'a role', 'BackEnd'

  describe '#start' do
    subject do
      BulkProcessor::BackEnd::ActiveJob.new(
        processor_class: MockCSVProcessor,
        payload: 'foo=bar',
        key: 'file.csv'
      )
    end

    it 'enqueues an ActiveJob' do
      expect(BulkProcessor::Job::ProcessCSV).to receive(:perform_later)
        .with('MockCSVProcessor', 'foo=bar', 'file.csv')
      subject.start
    end
  end
end
