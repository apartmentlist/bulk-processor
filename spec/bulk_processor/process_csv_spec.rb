describe BulkProcessor::ProcessCSV do
  describe '#perform' do
    subject do
      BulkProcessor::ProcessCSV.new(MockCSVProcessor, { 'other' => 'data' },
                                    'file.csv')
    end

    let(:csv_processor) { instance_double(BulkProcessor::Role::CSVProcessor) }

    before do
      MockFile.new('file.csv').write("species\ndog")
      allow(MockCSVProcessor).to receive(:new).with(
        CSV.parse("species\ndog", headers: true),
        payload: { 'other' => 'data', 'key' => 'file.csv' }
      ).and_return(csv_processor)
      allow(csv_processor).to receive(:start)
    end

    after { MockFile.cleanup }

    it 'starts a new CSVProcessor instance' do
      expect(csv_processor).to receive(:start)
      subject.perform
    end

    it 'removes the file' do
      subject.perform
      expect(MockFile.new('file.csv')).to_not exist
    end

    context 'when processing raises an error' do
      before do
        allow(csv_processor).to receive(:start).and_raise(StandardError, 'Uh oh!')
      end

      it 'removes the file' do
        begin
          subject.perform
          expect(MockFile.new('file.csv')).to_not exist
        rescue
        end
      end
    end
  end
end
