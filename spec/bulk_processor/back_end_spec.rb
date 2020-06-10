# frozen_string_literal: true

describe BulkProcessor::BackEnd do
  describe '.start' do
    before do
      @orig_back_end = BulkProcessor.config.back_end
      BulkProcessor.config.back_end = back_end_setting
    end

    after { BulkProcessor.config.back_end = @orig_back_end }

    context 'with an :active_job back end' do
      let(:back_end_setting) { :active_job }
      let(:back_end) { instance_double(BulkProcessor::BackEnd::ActiveJob) }

      before do
        allow(BulkProcessor::BackEnd::ActiveJob).to receive(:new).with(
          processor_class: MockCSVProcessor,
          payload: { 'foo' => 'bar' },
          key: 'file.csv',
          job: 'start-active-job-test'
        ).and_return(back_end)
      end

      it 'starts the ActiveJob backend' do
        expect(back_end).to receive(:start)
        BulkProcessor::BackEnd.start(
          processor_class: MockCSVProcessor,
          payload: { 'foo' => 'bar' },
          key: 'file.csv',
          job: 'start-active-job-test'
        )
      end

      context 'when num_processes is 2' do
        it 'split using the ActiveJob backend' do
          expect(back_end).to receive(:split).with(2)
          BulkProcessor::BackEnd.start(
            processor_class: MockCSVProcessor,
            payload: { 'foo' => 'bar' },
            key: 'file.csv',
            num_processes: 2,
            job: 'start-active-job-test'
          )
        end
      end
    end

    context 'with a :dynosaur back end' do
      let(:back_end_setting) { :dynosaur }
      let(:back_end) { instance_double(BulkProcessor::BackEnd::Dynosaur) }

      before do
        allow(BulkProcessor::BackEnd::Dynosaur).to receive(:new).with(
          processor_class: MockCSVProcessor,
          payload: { 'foo' => 'bar' },
          key: 'file.csv',
          job: 'start-dynosaur-test'
        ).and_return(back_end)
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'starts the Dynosaur backend' do
        expect(back_end).to receive(:start)
        BulkProcessor::BackEnd.start(
          processor_class: MockCSVProcessor,
          payload: { 'foo' => 'bar' },
          key: 'file.csv',
          job: 'start-dynosaur-test'
        )
      end

      context 'when num_processes is 2' do
        it 'split using the ActiveJob backend' do
          expect(back_end).to receive(:split).with(2)
          BulkProcessor::BackEnd.start(
            processor_class: MockCSVProcessor,
            payload: { 'foo' => 'bar' },
            key: 'file.csv',
            num_processes: 2,
            job: 'start-dynosaur-test'
          )
        end
      end
    end
  end
end
