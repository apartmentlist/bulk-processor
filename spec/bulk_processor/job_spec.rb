describe BulkProcessor::Job do
  context 'when a SIGTERM is received' do
    before do
      allow_any_instance_of(TestItemProcessor)
        .to receive(:process!).and_raise(SignalException, 'SIGTERM')
    end

    it 're-raises the SignalException' do
      expect do
        job = BulkProcessor::Job.new
        job.perform([{ 'species' => 'dog' }], 'TestItemProcessor', 'TestHandler', {})
      end.to raise_error(SignalException)
    end
  end
end
