require 'bulk_processor/back_end/gcp_pods/process_csv_task'

describe 'bulk_processor namespace' do
  describe 'bulk_processor:start' do
    let(:performer) { instance_double(BulkProcessor::ProcessCSV, perform: true) }
    let(:rake_cmd) do
      'bulk_processor:start[MockCSVProcessor,foo=bar,file.csv]'
    end

    before(:all) { Rake::Task.define_task(:environment) }

    before do
      Rake::Task['bulk_processor:start'].reenable # allows multiple calls
      allow(BulkProcessor::ProcessCSV).to receive(:new).and_return(performer)
    end

    it 'initializes the BulkProcessor::ProcessCSV with the correct args' do
      expect(BulkProcessor::ProcessCSV).to receive(:new)
        .with(MockCSVProcessor, { 'foo' => 'bar' }, 'file.csv')
        .and_return(performer)
      Rake.application.invoke_task(rake_cmd)
    end

    it 'starts the performer' do
      expect(performer).to receive(:perform)
      Rake.application.invoke_task(rake_cmd)
    end
  end
end
