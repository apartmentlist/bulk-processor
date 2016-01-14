include ActiveJob::TestHelper

describe BulkProcessor do
  describe '#start' do
    subject do
      BulkProcessor.new(stream: stream, processor_class: MockCSVProcessor)
    end

    let(:required_columns) { [] }
    let(:optional_columns) { ['name'] }
    let(:stream) { StringIO.new(csv) }
    let(:csv) { "name\nRex" }
    let(:handler) { instance_double(BulkProcessor::Role::Handler, complete!: true) }

    before do
      allow(MockCSVProcessor).to receive(:required_columns)
        .and_return(required_columns)
      allow(MockCSVProcessor).to receive(:optional_columns)
        .and_return(optional_columns)
      allow(MockHandler).to receive(:new).and_return(handler)
    end

    after { clear_enqueued_jobs }

    context 'with an invalid file' do
      context 'with missing required column' do
        let(:required_columns) { ['foo'] }

        it 'rejects the file with errors and payload' do
          expect(subject.start).to eq(false)
          expect(subject.errors).to include('Missing required column(s): foo')
        end
      end

      context 'extra column present' do
        let(:optional_columns) { [] }

        it 'rejects the file with errors' do
          message = 'Unrecognized column(s) found: name'

          expect(subject.start).to eq(false)
          expect(subject.errors).to include(message)
        end
      end

      context 'blank header' do
        let(:csv) { ",name\n1,Rex" }

        it 'rejects the file with errors' do
          message = 'Missing or malformed column header, is one of them blank?'

          expect(subject.start).to eq(false)
          expect(subject.errors).to include(message)
        end
      end
    end

    context 'sucessfully processed the file' do
      subject do
        BulkProcessor.new(stream: stream, processor_class: MockCSVProcessor,
                          payload: { my: 'stuff' })
      end

      it 'calls #complete! on the handler' do
        perform_enqueued_jobs do
          expect(handler).to receive(:complete!)
          subject.start
        end
      end
    end

    context 'failed to process the whole file' do
      before do
        allow_any_instance_of(MockRowProcessor)
          .to receive(:process!).and_raise(StandardError, 'Uh oh!')
      end

      it 'calls #fail! with the fatal error' do
        perform_enqueued_jobs do
          begin
            expect(handler).to receive(:fail!).with(instance_of(StandardError))
            subject.start
          rescue SignalException
          end
        end
      end
    end

    context 'the job receives a SignalError' do
      before do
        allow_any_instance_of(MockRowProcessor)
          .to receive(:process!).and_raise(SignalException, 'SIGTERM')
      end

      it 'calls .complete with the fatal error' do
        perform_enqueued_jobs do
          begin
            expect(handler).to receive(:fail!).with(instance_of(SignalException))
            subject.start
          rescue SignalException
          end
        end
      end
    end
  end
end
