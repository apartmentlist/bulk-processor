require 'gcp_manager'
require 'bulk_processor/back_end/gcp'

describe BulkProcessor::BackEnd::Gcp do
  subject(:gcp) do
    BulkProcessor::BackEnd::Gcp.new(
      processor_class: MockCSVProcessor,
      payload: { 'foo' => 'bar' },
      key: 'file.csv'
    )
  end

  before do
    allow(GcpManager).to receive(:create_and_deploy_job)
  end

  it_behaves_like 'a role', 'BackEnd'

  describe '#start' do
    it 'initializes a Dynosaur dyno with the correct args' do
      args = ['MockCSVProcessor', 'foo=bar', 'file.csv']

      expect(GcpManager)
        .to receive(:create_and_deploy_job)
        .with('start-bulk-processor', args)
      gcp.start
    end
  end

  describe '#split' do
    it 'initializes a Dynosaur dyno with the correct args' do
      args = ['MockCSVProcessor', 'foo=bar', 'file.csv', '2']

      expect(GcpManager)
        .to receive(:create_and_deploy_job)
        .with('split-bulk-processor', args)
      gcp.split(2)
    end

  end
end
