describe BulkProcessor::Job do
  describe '#perform' do
    let(:csv_processor) { instance_double(BulkProcessor::Role::CSVProcessor) }
    let(:csv_str) { "species\ndog" }
    let(:payload) { { 'other' => 'data' } }

    before do
      MockFile.new('file.csv').write(csv_str)
      allow(csv_processor).to receive(:start)
      allow(MockCSVProcessor).to receive(:new)
        .with(CSV.parse(csv_str, headers: true), payload: payload)
        .and_return(csv_processor)
    end

    after { MockFile.cleanup }

    it 'starts a new CSVProcessor instance' do
      expect(csv_processor).to receive(:start)
      subject.perform('MockCSVProcessor', payload.to_json, 'MockFile', 'file.csv')
    end

    it 'removes the file' do
      subject.perform('MockCSVProcessor', payload.to_json, 'MockFile', 'file.csv')
      expect(MockFile.new('file.csv')).to_not exist
    end

    context 'when processing raises an error' do
      before do
        allow(csv_processor).to receive(:start).and_raise(StandardError, 'Uh oh!')
      end

      it 'removes the file' do
        begin
          subject.perform('MockCSVProcessor', payload.to_json, 'MockFile', 'file.csv')
          expect(MockFile.new('file.csv')).to_not exist
        rescue
        end
      end
    end
  end
end
