include ActiveJob::TestHelper

describe BulkProcessor do
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
          message = 'Missing required column(s): foo'
          expect(TestHandler)
            .to receive(:invalid).with({ my: 'stuff' }, array_including(message))

          BulkProcessor
            .process(stream, TestItemProcessor, TestHandler, { my: 'stuff' })
        end
      end

      context 'extra column present' do
        let(:optional_columns) { [] }

        it 'rejects the file with errors' do
          message = 'Unrecognized column(s) found: name'
          expect(TestHandler)
            .to receive(:invalid).with({}, array_including(message))

          BulkProcessor.process(stream, TestItemProcessor, TestHandler)
        end
      end

      context 'blank header' do
        let(:csv) { ",name\n1,Rex" }

        it 'rejects the file with errors' do
          message = 'Missing or malformed column header'
          expect(TestHandler)
            .to receive(:invalid).with({}, array_including(message))

          BulkProcessor.process(stream, TestItemProcessor, TestHandler)
        end
      end
    end

    context 'with a valid file' do
      it 'enqueues the work' do
        BulkProcessor.process(stream, TestItemProcessor, TestHandler)
        expect(enqueued_jobs.length).to eq(1)
      end

      it 'strips non-UTF-8 characters from the stream' do
        perform_enqueued_jobs do
          stream = StringIO.new("name\nyen=\xA5")
          expect(TestItemProcessor)
            .to receive(:new).with('name' => 'yen=').and_call_original
          BulkProcessor.process(stream, TestItemProcessor, TestHandler)
        end
      end
    end

    context 'sucessfully processed the file' do
      it 'calls .complete on the handler with the original payload' do
        perform_enqueued_jobs do
          expect(TestHandler)
            .to receive(:complete).with({ my: 'stuff' }, anything, anything)
          BulkProcessor
            .process(stream, TestItemProcessor, TestHandler, { my: 'stuff' })
        end
      end

      it 'calls .complete on the handler with successes' do
        perform_enqueued_jobs do
          expect(TestHandler)
            .to receive(:complete).with(anything, { 0 => [] }, anything)
          BulkProcessor.process(stream, TestItemProcessor, TestHandler)
        end
      end

      context 'but one row fails' do
        let(:csv) { "name\nSocks" }

        it 'calls .complete on the handler with failures' do
          perform_enqueued_jobs do
            expect(TestHandler)
              .to receive(:complete)
                    .with(anything, anything, { 0 => ['bad dog'] })
            BulkProcessor.process(stream, TestItemProcessor, TestHandler)
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
          BulkProcessor.process(stream, TestItemProcessor, TestHandler)
        end
      end
    end
  end
end
