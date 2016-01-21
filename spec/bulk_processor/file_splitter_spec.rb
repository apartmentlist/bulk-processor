describe BulkProcessor::FileSplitter do
  describe '#split!' do
    subject do
      BulkProcessor::FileSplitter.new(key: key, row_chunker: row_chunker)
    end

    let(:key) { 'foo/test.csv' }
    let(:csv_str) do
      "property_id,unit_name\n" \
      "1,A\n" \
      "2,B\n" \
      "3,C\n" \
      "4,D\n" \
    end
    let(:row_chunker) do
      instance_double(BulkProcessor::Role::RowChunker, ranges_for: ranges)
    end
    let(:ranges) { [(0..1), (2..3)] }

    before { MockFile.new(key).write(csv_str) }

    after { MockFile.cleanup }

    it 'returns the requested number of keys' do
      expect(subject.split!.count).to eq(2)
    end

    it 'names the keys properly' do
      keys = subject.split!
      expect(keys[0]).to eq('foo/test_1-of-2.csv')
      expect(keys[1]).to eq('foo/test_2-of-2.csv')
    end

    it 'creates the correct files based on the boundary_column' do
      keys = subject.split!
      MockFile.new(keys[0]).open do |file|
        expect(file.read)
          .to eq("property_id,unit_name\n1,A\n2,B\n")
      end
      MockFile.new(keys[1]).open do |file|
        expect(file.read).to eq("property_id,unit_name\n3,C\n4,D\n")
      end
    end

    context 'when the key has no dots' do
      let(:key) { 'foo/test' }

      it 'does not add an extension to the keys' do
        keys = subject.split!
        expect(keys[0]).to eq('foo/test_1-of-2')
        expect(keys[1]).to eq('foo/test_2-of-2')
      end
    end

    context 'when the key has 2 dots' do
      let(:key) { 'foo/2015.10.31 all.csv' }

      it 'treats everything before the last dot as the name' do
        keys = subject.split!
        expect(keys[0]).to eq('foo/2015.10.31 all_1-of-2.csv')
        expect(keys[1]).to eq('foo/2015.10.31 all_2-of-2.csv')
      end
    end

    context 'when there is no content for one file' do
      let(:ranges) { [(0..3), (4..3)] }

      it 'writes headers but no rows for that file' do
        keys = subject.split!
        MockFile.new(keys[0]).open do |file|
          expect(file.read)
            .to eq("property_id,unit_name\n1,A\n2,B\n3,C\n4,D\n")
        end
        MockFile.new(keys[1]).open do |file|
          expect(file.read).to eq("property_id,unit_name\n")
        end
      end
    end
  end
end
