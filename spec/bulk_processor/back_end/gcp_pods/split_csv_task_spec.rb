require 'bulk_processor/back_end/gcp_pods/split_csv_task'

describe 'bulk_processor namespace' do
  describe 'bulk_processor:split' do
    let(:performer) { instance_double(BulkProcessor::SplitCSV, perform: true) }
    let(:rake_cmd) do
      'bulk_processor_gcp_pods:split[MockCSVProcessor,foo=bar,file.csv,2]'
    end

    before(:all) { Rake::Task.define_task(:environment) }

    before do
      Rake::Task['bulk_processor_gcp_pods:split'].reenable # allows multiple calls
      allow(BulkProcessor::SplitCSV).to receive(:new).and_return(performer)
    end

    it 'initializes the BulkProcessor::ProcessCSV with the correct args' do
      expect(BulkProcessor::SplitCSV).to receive(:new)
        .with(MockCSVProcessor, { 'foo' => 'bar' }, 'file.csv', 2)
        .and_return(performer)
      Rake.application.invoke_task(rake_cmd)
    end

    it 'starts the performer' do
      expect(performer).to receive(:perform)
      Rake.application.invoke_task(rake_cmd)
    end
  end
end
