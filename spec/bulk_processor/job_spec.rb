describe BulkProcessor::Job do
  describe '#perform' do
    let(:csv_processor) { instance_double(BulkProcessor::Role::CSVProcessor) }
    let(:records) { [{ 'species' => 'dog' }] }
    let(:payload) { { 'other' => 'data' } }

    before do
      allow(MockCSVProcessor).to receive(:new)
        .with(records, payload: payload).and_return(csv_processor)
    end

    it 'starts a new CSVProcessor instance' do
      expect(csv_processor).to receive(:start)
      subject.perform(records, 'MockCSVProcessor', payload)
    end
  end
end
