describe BulkProcessor::SplitCSV do
  describe '#perform' do
    subject do
      BulkProcessor::SplitCSV.new(MockCSVProcessor, { 'other' => 'data' },
                                  'file.csv', 2)
    end

    let(:csv_str) { "pet_id,name\n1,ralph\n1,fido\n1,spike\n2,meowzer" }
    let(:payload) { { 'other' => 'data' } }

    before do
      MockFile.new('file.csv').write(csv_str)
      allow(BulkProcessor::BackEnd).to receive(:start)
    end

    after { MockFile.cleanup }

    shared_examples_for 'a splitter' do
      it 'starts the processing on the back-end with 2 new files' do
        %w[file_1-of-2.csv file_2-of-2.csv].each do |key|
          expect(BulkProcessor::BackEnd).to receive(:start).with(
            processor_class: MockCSVProcessor,
            payload: { 'other' => 'data' },
            key: key
          )
        end
        subject.perform
      end

      it 'not remove the file' do
        subject.perform
        expect(MockFile.new('file.csv')).to exist
      end

      context 'when starting a processing job raises an error' do
        let(:handler) { instance_double(BulkProcessor::Role::Handler, fail!: true) }
        let(:error) { StandardError.new('Uh oh!') }

        before do
          allow(MockCSVProcessor).to receive(:handler).and_return(MockHandler)
          payload = { 'key' => 'file.csv', 'other' => 'data' }
          allow(MockHandler).to receive(:new).with(payload: payload, results: [])
            .and_return(handler)
          allow(BulkProcessor::BackEnd).to receive(:start).and_raise(error)
        end

        it 'handles the error' do
          begin
            expect(handler).to receive(:fail!).with(error)
            subject.perform
          rescue
          end
        end

        it 'removes the file' do
          begin
            subject.perform
            expect(MockFile.new('file.csv')).to_not exist
          rescue
          end
        end
      end
    end

    context 'when the processor class does not define .boundary_column' do
      it_behaves_like 'a splitter'

      it 'splits the CSV evenly' do
        subject.perform
        file_1_contents = 'deadbeef'
        file_2_contents = 'deadbeef'
        MockFile.new('file_1-of-2.csv').open { |f| file_1_contents = f.read }
        MockFile.new('file_2-of-2.csv').open { |f| file_2_contents = f.read }
        expect(file_1_contents).to eq("pet_id,name\n1,ralph\n1,fido\n")
        expect(file_2_contents).to eq("pet_id,name\n1,spike\n2,meowzer\n")
      end
    end

    context 'when the processor class defines .boundary_column' do
      before do
        allow(MockCSVProcessor).to receive(:boundary_column).and_return('pet_id')
      end

      it_behaves_like 'a splitter'

      it 'splits the CSV respecting the boundary column' do
        subject.perform
        file_1_contents = 'deadbeef'
        file_2_contents = 'deadbeef'
        MockFile.new('file_1-of-2.csv').open { |f| file_1_contents = f.read }
        MockFile.new('file_2-of-2.csv').open { |f| file_2_contents = f.read }
        expect(file_1_contents).to eq("pet_id,name\n1,ralph\n1,fido\n1,spike\n")
        expect(file_2_contents).to eq("pet_id,name\n2,meowzer\n")
      end
    end
  end
end
