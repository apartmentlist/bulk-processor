require 'gcp_job_manager'
require 'bulk_processor/back_end/gcp_pods'

describe BulkProcessor::BackEnd::GcpPods do
  subject(:gcp_pods) do
    BulkProcessor::BackEnd::GcpPods.new(
      processor_class: MockCSVProcessor,
      payload: { 'foo' => 'bar' },
      key: 'file.csv'
    )
  end

  before do
    allow(GcpJobManager).to receive(:create_and_deploy_job)
  end

  it_behaves_like 'a role', 'BackEnd'

  describe '#start' do
    it 'initializes a Dynosaur dyno with the correct args' do
      args = ['MockCSVProcessor', 'foo=bar', 'file.csv']

      expect(GcpJobManager)
        .to receive(:create_and_deploy_job)
        .with('start-bulk-processor', args)
      gcp_pods.start
    end
  end

  describe '#split' do
    it 'initializes a Dynosaur dyno with the correct args' do
      args = ['MockCSVProcessor', 'foo=bar', 'file.csv', '2']

      expect(GcpJobManager)
        .to receive(:create_and_deploy_job)
        .with('split-bulk-processor', args)
      gcp_pods.split(2)
    end

  end
end
