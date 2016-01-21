describe BulkProcessor::BackEnd do
  describe '.start' do
    context 'with an :active_job back end' do
      let(:back_end) { instance_double(BulkProcessor::BackEnd::ActiveJob) }

      before do
        @back_end = BulkProcessor.config.back_end
        BulkProcessor.config.back_end = :active_job
        allow(BulkProcessor::BackEnd::ActiveJob).to receive(:new).with(
          processor_class: MockCSVProcessor, payload: 'foo=bar', key: 'file.csv'
        ).and_return(back_end)
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'starts the ActiveJob backend' do
        expect(back_end).to receive(:start)
        BulkProcessor::BackEnd.start(processor_class: MockCSVProcessor,
                                     payload: { foo: 'bar' }, key: 'file.csv')
      end

      context 'when num_processes is 2' do
        it 'split using the ActiveJob backend' do
          expect(back_end).to receive(:split).with(2)
          BulkProcessor::BackEnd.start(processor_class: MockCSVProcessor,
                                       payload: { foo: 'bar' }, key: 'file.csv',
                                       num_processes: 2)
        end
      end
    end

    context 'with a :dynosaur back end' do
      let(:back_end) { instance_double(BulkProcessor::BackEnd::Dynosaur) }

      before do
        @back_end = BulkProcessor.config.back_end
        BulkProcessor.config.back_end = :dynosaur
        allow(BulkProcessor::BackEnd::Dynosaur).to receive(:new).with(
          processor_class: MockCSVProcessor, payload: 'foo=bar', key: 'file.csv'
        ).and_return(back_end)
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'starts the Dynosaur backend' do
        expect(back_end).to receive(:start)
        BulkProcessor::BackEnd.start(processor_class: MockCSVProcessor,
                                     payload: { foo: 'bar' }, key: 'file.csv')
      end

      context 'when num_processes is 2' do
        it 'split using the ActiveJob backend' do
          expect(back_end).to receive(:split).with(2)
          BulkProcessor::BackEnd.start(processor_class: MockCSVProcessor,
                                       payload: { foo: 'bar' }, key: 'file.csv',
                                       num_processes: 2)
        end
      end
    end
  end
end
