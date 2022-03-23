describe SplitCSVJob do
  let(:split_job) { subject }

  describe '#perform' do
    let(:performer) { instance_double(BulkProcessor::SplitCSV, perform: true) }
    let(:num_chunks) { 3 }

    before do
      allow(BulkProcessor::SplitCSV)
        .to receive(:new)
        .with(MockCSVProcessor, { 'foo' => 'bar' }, 'file.csv', num_chunks)
        .and_return(performer)
    end

    it 'initializes the BulkProcessor::ProcessCSV with the correct args' do
      expect(BulkProcessor::SplitCSV)
        .to receive(:new)
        .with(MockCSVProcessor, { 'foo' => 'bar' }, 'file.csv', num_chunks)
        .and_return(performer)
      split_job.perform('MockCSVProcessor','foo=bar','file.csv', num_chunks)
    end

    it 'starts the performer' do
      expect(performer).to receive(:perform)
      split_job.perform('MockCSVProcessor','foo=bar','file.csv', num_chunks)
    end
  end
end
