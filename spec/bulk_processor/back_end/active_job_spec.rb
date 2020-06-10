# frozen_string_literal: true

require 'bulk_processor/back_end/active_job'

describe BulkProcessor::BackEnd::ActiveJob do
  it_behaves_like 'a role', 'BackEnd'

  describe '#start' do
    subject do
      BulkProcessor::BackEnd::ActiveJob.new(
        processor_class: MockCSVProcessor,
        payload: { 'foo' => 'bar' },
        key: 'file.csv',
        job: nil
      )
    end

    it 'enqueues an ActiveJob' do
      expect(BulkProcessor::BackEnd::ActiveJob::ProcessCSVJob)
        .to receive(:perform_later)
        .with('MockCSVProcessor', 'foo=bar', 'file.csv')
      subject.start
    end
  end

  describe '#split' do
    subject do
      BulkProcessor::BackEnd::ActiveJob.new(
        processor_class: MockCSVProcessor,
        payload: { 'foo' => 'bar' },
        key: 'file.csv',
        job: nil
      )
    end

    it 'enqueues an ActiveJob' do
      expect(BulkProcessor::BackEnd::ActiveJob::SplitCSVJob)
        .to receive(:perform_later)
        .with('MockCSVProcessor', 'foo=bar', 'file.csv', 2)
      subject.split(2)
    end
  end
end
