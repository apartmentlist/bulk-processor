describe ProcessCSVJob do
  let(:process_job) { subject }
  
  describe '#perform' do
    let(:performer) { instance_double(BulkProcessor::ProcessCSV, perform: true) }

    before do
      allow(BulkProcessor::ProcessCSV)
        .to receive(:new)
        .with(MockCSVProcessor, { 'foo' => 'bar' }, 'file.csv')
        .and_return(performer)
    end

    it 'initializes the BulkProcessor::ProcessCSV with the correct args' do
      expect(BulkProcessor::ProcessCSV)
        .to receive(:new)
        .with(MockCSVProcessor, { 'foo' => 'bar' }, 'file.csv')
        .and_return(performer)
      process_job.perform('MockCSVProcessor','foo=bar','file.csv')
    end

    it 'starts the performer' do
      expect(performer).to receive(:perform)
      process_job.perform('MockCSVProcessor','foo=bar','file.csv')
    end
  end
end
