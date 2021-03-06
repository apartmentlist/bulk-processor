include ActiveJob::TestHelper

describe BulkProcessor do
  describe '#start' do
    subject do
      BulkProcessor.new(key: 'file.csv', stream: stream,
                        processor_class: MockCSVProcessor)
    end

    let(:required_columns) { [] }
    let(:optional_columns) { ['name'] }
    let(:stream) { StringIO.new(csv_str) }
    let(:csv_str) { "name\nRex" }
    let(:handler) { instance_double(BulkProcessor::Role::Handler, complete!: true) }

    before do
      allow(MockCSVProcessor).to receive(:required_columns)
        .and_return(required_columns)
      allow(MockCSVProcessor).to receive(:optional_columns)
        .and_return(optional_columns)
      allow(MockHandler).to receive(:new).and_return(handler)
    end

    after do
      clear_enqueued_jobs
      MockFile.cleanup
    end

    it 'persists the file' do
      contents = 'deadbeef'
      subject.start
      MockFile.new('file.csv').open do |file|
        contents = file.read
      end
      expect(contents).to eq("name\nRex")
    end

    it 'returns true' do
      expect(subject.start).to eq(true)
    end

    context 'when using the :active_job back end' do
      before do
        @back_end = BulkProcessor.config.back_end
        BulkProcessor.config.back_end = :active_job
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'enqueues a process job' do
        expect(BulkProcessor::BackEnd::ActiveJob::ProcessCSVJob)
          .to receive(:perform_later)
          .with('MockCSVProcessor', '', 'file.csv')
        subject.start
      end

      context 'when starting with 2 processes' do
        it 'enqueues a split job' do
          expect(BulkProcessor::BackEnd::ActiveJob::SplitCSVJob)
            .to receive(:perform_later)
            .with('MockCSVProcessor', '', 'file.csv', 2)
          subject.start(2)
        end
      end
    end

    context 'when using the :dynosaur back end' do
      let(:dyno) { instance_double(Dynosaur::Process::Heroku, start: true) }

      before do
        @back_end = BulkProcessor.config.back_end
        BulkProcessor.config.back_end = :dynosaur
        allow(Dynosaur::Process::Heroku).to receive(:new).and_return(dyno)
      end

      after { BulkProcessor.config.back_end = @back_end }

      it 'initializes a Dynosaur dyno for a process job' do
        args = {
          task: 'bulk_processor:start',
          args: ['MockCSVProcessor', '', 'file.csv']
        }
        expect(Dynosaur::Process::Heroku).to receive(:new).with(args).and_return(dyno)
        subject.start
      end

      it 'starts a Dynosaur dyno' do
        expect(dyno).to receive(:start)
        subject.start
      end

      context 'when starting with 2 processes' do
        it 'initializes a Dynosaur dyno for a split job' do
          args = {
            task: 'bulk_processor:split',
            args: ['MockCSVProcessor', '', 'file.csv', '2']
          }
          expect(Dynosaur::Process::Heroku).to receive(:new).with(args).and_return(dyno)
          subject.start(2)
        end
      end
    end

    context 'when there is an error enqueuing the job' do
      before do
        expect(BulkProcessor::BackEnd::ActiveJob::ProcessCSVJob)
          .to receive(:perform_later)
          .and_raise(StandardError, 'Uh oh!')
      end

      it 'removes the file' do
        subject.start rescue nil
        expect(MockFile.new('file.csv').exists?).to eq(false)
      end
    end

    context 'when the file is already being processed' do
      before { MockFile.new('file.csv').write(csv_str) }

      it 'does not enqueue a job' do
        expect(BulkProcessor::BackEnd::ActiveJob::ProcessCSVJob)
          .to receive(:perform_later).never
        subject.start
      end

      it 'returns false' do
        expect(subject.start).to eq(false)
      end

      it 'adds a useful error' do
        message = 'Already processing file.csv, please wait for it to finish'
        subject.start
        expect(subject.errors).to include(message)
      end
    end

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
        let(:csv_str) { ",name\n1,Rex" }

        it 'rejects the file with errors' do
          message = 'Missing or malformed column header, is one of them blank?'

          expect(subject.start).to eq(false)
          expect(subject.errors).to include(message)
        end
      end
    end

    context 'sucessfully processed the file' do
      subject do
        BulkProcessor.new(key: 'file.csv', stream: stream, payload: {},
                          processor_class: MockCSVProcessor)
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
          expect(handler).to receive(:fail!).with(instance_of(StandardError))
          subject.start
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
