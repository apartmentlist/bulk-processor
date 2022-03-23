require 'bulk_processor/back_end/sidekiq_job'
require_relative '../../../lib/jobs/process_csv_job'
require_relative '../../../lib/jobs/split_csv_job'

describe BulkProcessor::BackEnd::SidekiqJob do
  subject(:sidekiq_job) do
    BulkProcessor::BackEnd::SidekiqJob.new(
      processor_class: MockCSVProcessor,
      payload: { 'foo' => 'bar' },
      key: 'file.csv'
    )
  end

  it_behaves_like 'a role', 'BackEnd'

  describe '#start' do
    it 'initializes a Dynosaur dyno with the correct args' do
      expect(ProcessCSVJob)
        .to receive(:perform_async)
        .with('MockCSVProcessor', 'foo=bar', 'file.csv')
      sidekiq_job.start
    end
  end

  describe '#split' do
    let(:split_num) { 10 }

    it 'initializes a Dynosaur dyno with the correct args' do
      expect(SplitCSVJob)
        .to receive(:perform_async)
        .with('MockCSVProcessor', 'foo=bar', 'file.csv', split_num)
      sidekiq_job.split(split_num)
    end
  end
end