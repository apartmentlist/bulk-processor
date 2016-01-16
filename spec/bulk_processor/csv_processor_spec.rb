require 'bulk_processor/csv_processor'

describe BulkProcessor::CSVProcessor do
  class TestCSVProcessor < BulkProcessor::CSVProcessor
  end

  before do
    allow(TestCSVProcessor).to receive(:row_processor_class)
      .and_return(MockRowProcessor)
    allow(TestCSVProcessor).to receive(:post_processor_class)
      .and_return(MockPostProcessor)
    allow(TestCSVProcessor).to receive(:handler_class).and_return(MockHandler)
  end

  it_behaves_like 'a role', 'CSVProcessor'

  describe '#start' do
    subject { TestCSVProcessor.new(csv, payload: payload) }

    let(:csv) { [{ 'name' => 'Rex' }, { 'name' => 'Fido' }] }
    let(:payload) { { 'relevant' => 'data' } }
    let(:row_processor_1) do
      instance_double(BulkProcessor::Role::RowProcessor, process!: true,
                                                         result: 'Result 1')
    end
    let(:row_processor_2) do
      instance_double(BulkProcessor::Role::RowProcessor, process!: true,
                                                         result: 'Result 2')
    end
    let(:post_processor) do
      instance_double(BulkProcessor::Role::PostProcessor, start: true, results: [])
    end

    before do
      allow(MockRowProcessor).to receive(:new)
        .with(hash_including('name' => 'Rex'), payload: payload)
        .and_return(row_processor_1)
      allow(MockRowProcessor).to receive(:new)
        .with(hash_including('name' => 'Fido'), payload: payload)
        .and_return(row_processor_2)
      allow(MockPostProcessor).to receive(:new)
        .with([row_processor_1, row_processor_2])
        .and_return(post_processor)
      allow(MockHandler).to receive(:complete)
    end

    it 'processes all rows' do
      expect(row_processor_1).to receive(:process!)
      expect(row_processor_2).to receive(:process!)
      subject.start
    end

    it 'post-processes the CSV' do
      expect(post_processor).to receive(:start)
      subject.start
    end

    context 'handling the results' do
      let(:handler) do
        instance_double(BulkProcessor::Role::Handler, complete!: true,
                                                      fail!: true)
      end

      before { allow(MockHandler).to receive(:new).and_return(handler) }

      it 'initializes the handler with the payload' do
        expect(MockHandler).to receive(:new)
          .with(payload: payload, results: anything)
          .and_return(handler)
        subject.start
      end

      it 'initializes the handler with results' do
        expected_results = ['Result 1', 'Result 2']
        expect(MockHandler).to receive(:new)
          .with(payload: anything, results: expected_results)
          .and_return(handler)
        subject.start
      end

      it 'sends a completion message the handler' do
        expect(handler).to receive(:complete!)
        subject.start
      end

      context 'when processing an item raises an unrescued error' do
        before do
          allow(row_processor_1).to receive(:process!)
            .and_raise(StandardError, 'Broken')
        end

        it 'sends a failure message the handler' do
          expect(handler).to receive(:fail!).with(instance_of(StandardError))
          subject.start
        end
      end

      context 'when processing an item raises a SIGTERM' do
        before do
          allow(row_processor_1).to receive(:process!)
            .and_raise(SignalException, 'SIGTERM')
        end

        it 're-raises the error' do
          expect do
            subject.start
          end.to raise_error(SignalException, 'SIGTERM')
        end
      end

      context 'when post-processing results in errors' do
        before { allow(post_processor).to receive(:results).and_return(['Err']) }

        it 'adds the errors to the errors hash' do
          expected_results = ['Err']
          expect(MockHandler).to receive(:new)
            .with(payload: anything, results: array_including(expected_results)
            ).and_return(handler)
          subject.start
        end
      end
    end
  end
end
