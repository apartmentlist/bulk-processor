require 'bulk_processor/back_end/active_job'

describe BulkProcessor::BackEnd::ActiveJob::ProcessCSVJob do
  describe '#perform' do
    let(:performer) { instance_double(BulkProcessor::ProcessCSV, perform: true) }

    before do
      allow(BulkProcessor::ProcessCSV).to receive(:new).and_return(performer)
    end

    it 'initializes a ProcessCSV with the deserialized args' do
      expect(BulkProcessor::ProcessCSV).to receive(:new)
        .with(MockCSVProcessor, { 'other' => 'data' }, 'file.csv')
        .and_return(performer)
      subject.perform('MockCSVProcessor', 'other=data', 'file.csv')
    end

    it 'starts the performer' do
      expect(performer).to receive(:perform)
      subject.perform('MockCSVProcessor', 'other=data', 'file.csv')
    end
  end
end
