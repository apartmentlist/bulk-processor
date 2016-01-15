include ActiveJob::TestHelper

describe BulkProcessor do
  class TestItemProcessor < MockItemProcessor
  end

  class TestHandler < MockHandler
  end

  describe '.process usage' do
    let(:required_columns) { [] }
    let(:optional_columns) { ['name'] }
    let(:stream) { StringIO.new(csv) }
    let(:csv) { "name\nRex" }

    before do
      TestItemProcessor.required_columns = required_columns
      TestItemProcessor.optional_columns = optional_columns
    end

    after { clear_enqueued_jobs }

    context 'with an invalid file' do
      context 'with missing required column' do
        let(:required_columns) { ['foo'] }

        it 'rejects the file with errors and payload' do
          processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)

          expect(processor.process).to eq(false)
          expect(processor.errors).to include('Missing required column(s): foo')
        end
      end

      context 'extra column present' do
        let(:optional_columns) { [] }

        it 'rejects the file with errors' do
          message = 'Unrecognized column(s) found: name'
          processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)

          expect(processor.process).to eq(false)
          expect(processor.errors).to include(message)
        end
      end

      context 'blank header' do
        let(:csv) { ",name\n1,Rex" }

        it 'rejects the file with errors' do
          message = 'Missing or malformed column header, is one of them blank?'
          processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)

          expect(processor.process).to eq(false)
          expect(processor.errors).to include(message)
        end
      end
    end

    context 'with a valid file' do
      it 'enqueues the work' do
        processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)

        expect(processor.process).to eq(true)
        expect(enqueued_jobs.length).to eq(1)
      end

      it 'strips non-UTF-8 characters from the stream' do
        perform_enqueued_jobs do
          stream = StringIO.new("name\nyen=\xA5")
          expect(TestItemProcessor)
            .to receive(:new).with({ 'name' => 'yen=' }, anything).and_call_original
          processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)
          processor.process
        end
      end
    end

    context 'sucessfully processed the file' do
      it 'calls .complete on the handler with the original payload' do
        perform_enqueued_jobs do
          expect(TestHandler)
            .to receive(:complete).with({ my: 'stuff' }, anything, anything, nil)
          processor =
            BulkProcessor.new(stream, TestItemProcessor, TestHandler, { my: 'stuff' })
          processor.process
        end
      end

      it 'calls .complete on the handler with successes' do
        perform_enqueued_jobs do
          expect(TestHandler)
            .to receive(:complete).with(anything, { 0 => [] }, anything, nil)
          processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)
          processor.process
        end
      end

      context 'but one row fails' do
        let(:csv) { "name\nSocks" }

        it 'calls .complete on the handler with failures' do
          perform_enqueued_jobs do
            expect(TestHandler)
              .to receive(:complete)
                    .with(anything, anything, { 0 => ['bad dog'] }, nil)
            processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)
            processor.process
          end
        end
      end
    end

    context 'failed to process the whole file' do
      let(:csv) { "name\nHuman" }

      it 'calls .complete with the fatal error' do
        perform_enqueued_jobs do
          expect(TestHandler)
            .to receive(:complete)
                  .with(anything, anything, anything, instance_of(RuntimeError))
          processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)
          processor.process
        end
      end
    end

    context 'the job receives a SignalError' do
      before do
        allow_any_instance_of(TestItemProcessor)
          .to receive(:process!).and_raise(SignalException, 'SIGTERM')
      end

      it 'calls .complete with the fatal error' do
        perform_enqueued_jobs do
          begin
            expect(TestHandler)
              .to receive(:complete)
                    .with(anything, anything, anything, instance_of(SignalException))

            processor = BulkProcessor.new(stream, TestItemProcessor, TestHandler)
            processor.process
          rescue SignalException
          end
        end
      end
    end
  end
end
