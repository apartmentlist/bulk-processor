require 'bulk_processor/csv_processor'

describe BulkProcessor::CSVProcessor do
  class TestCSVProcessor < BulkProcessor::CSVProcessor
  end

  before do
    allow(TestCSVProcessor).to receive(:row_processor_class)
      .and_return(MockRowProcessor)
    allow(TestCSVProcessor).to receive(:handler_class).and_return(MockHandler)
  end

  it_behaves_like 'a role', 'CSVProcessor'

  describe '#start' do
    subject { TestCSVProcessor.new(records, payload: payload) }

    let(:records) { [{ 'name' => 'Rex' }, { 'name' => 'Fido' }] }
    let(:payload) { { 'relevant' => 'data' } }
    let(:row_processor_1) do
      instance_double(BulkProcessor::Role::RowProcessor, process!: true,
                                                         success?: true,
                                                         messages: ['Woah 1'])
    end
    let(:row_processor_2) do
      instance_double(BulkProcessor::Role::RowProcessor, process!: true,
                                                         success?: true,
                                                         messages: ['Woah 2'])
    end

    before do
      allow(MockRowProcessor).to receive(:new)
        .with({ 'name' => 'Rex' }, payload: payload)
        .and_return(row_processor_1)
      allow(MockRowProcessor).to receive(:new)
        .with({ 'name' => 'Fido' }, payload: payload)
        .and_return(row_processor_2)
      allow(MockHandler).to receive(:complete)
    end

    it 'processes all records' do
      expect(row_processor_1).to receive(:process!)
      expect(row_processor_2).to receive(:process!)
      subject.start
    end

    context 'handling the results' do
      let(:handler) do
        instance_double(BulkProcessor::Role::Handler, complete!: true,
                                                      fail!: true)
      end

      before do
        allow(MockHandler).to receive(:new).and_return(handler)
        allow(row_processor_2).to receive(:success?).and_return(false)
      end

      it 'initializes the handler with the payload' do
        expect(MockHandler).to receive(:new)
          .with(payload: payload, successes: anything, errors: anything)
          .and_return(handler)
        subject.start
      end

      it 'initializes the handler with successes' do
        expected_successes = { 0 => ['Woah 1'] }
        expect(MockHandler).to receive(:new)
          .with(payload: anything, successes: expected_successes, errors: anything)
          .and_return(handler)
        subject.start
      end

      it 'initializes the handler with errors' do
        expected_errors = { 1 => ['Woah 2'] }
        expect(MockHandler).to receive(:new)
          .with(payload: anything, successes: anything, errors: expected_errors)
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
    end
  end
end
