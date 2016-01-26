require 'bulk_processor/back_end/active_job'

describe BulkProcessor::BackEnd::ActiveJob::SplitCSVJob do
  describe '#perform' do
    let(:performer) { instance_double(BulkProcessor::SplitCSV, perform: true) }

    before do
      allow(BulkProcessor::SplitCSV).to receive(:new).and_return(performer)
    end

    it 'initializes a ProcessCSV with the deserialized args' do
      expect(BulkProcessor::SplitCSV).to receive(:new)
        .with(MockCSVProcessor, { 'other' => 'data' }, 'file.csv', 2)
        .and_return(performer)
      subject.perform('MockCSVProcessor', 'other=data', 'file.csv', 2)
    end

    it 'starts the performer' do
      expect(performer).to receive(:perform)
      subject.perform('MockCSVProcessor', 'other=data', 'file.csv', 2)
    end
  end
end
