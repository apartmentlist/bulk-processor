require 'rake'
require 'bulk_processor/tasks'

describe 'bulk_processor namespace' do
  describe 'bulk_processor:start' do
    let(:job) { instance_double(BulkProcessor::Job, perform: true) }

    before { allow(BulkProcessor::Job).to receive(:new).and_return(job) }

    it 'starts the job' do
      expect(job).to receive(:perform)
        .with('MockCSVProcessor', '{"foo":"bar"}', 'MockFile', 'file.csv')
      Rake::Task['bulk_processor:start'].reenable # allows multiple calls
      rake_cmd =
        'bulk_processor:start[MockCSVProcessor,{"foo":"bar"},MockFile,file.csv]'
      Rake.application.invoke_task(rake_cmd)
    end
  end
end
