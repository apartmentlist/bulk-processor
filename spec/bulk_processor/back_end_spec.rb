describe BulkProcessor::BackEnd do
  describe '.start' do
    let(:common_args) do
      {
        processor_class: MockCSVProcessor,
        payload: { foo: 'bar' },
        key: 'file.csv'
      }
    end

    context 'with an :active_job back end' do
      let(:back_end) { instance_double(BulkProcessor::BackEnd::ActiveJob) }

      before do
        @back_end = BulkProcessor.config.back_end
        BulkProcessor.config.back_end = :active_job
        allow(BulkProcessor::BackEnd::ActiveJob).to receive(:new)
          .with(common_args).and_return(back_end)
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'starts the ActiveJob backend' do
        expect(back_end).to receive(:start)
        BulkProcessor::BackEnd.start(common_args)
      end
    end

    context 'with a :dynosaur back end' do
      let(:back_end) { instance_double(BulkProcessor::BackEnd::Dynosaur) }

      before do
        @back_end = BulkProcessor.config.back_end
        BulkProcessor.config.back_end = :dynosaur
        allow(BulkProcessor::BackEnd::Dynosaur).to receive(:new)
          .with(common_args).and_return(back_end)
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'starts the Dynosaur backend' do
        expect(back_end).to receive(:start)
        BulkProcessor::BackEnd.start(common_args)
      end
    end
  end
end
