describe BulkProcessor::RowChunker::Balanced do
  it_behaves_like 'a role', 'RowChunker'

  describe '#ranges_for' do
    subject { BulkProcessor::RowChunker::Balanced.new(num_chunks) }

    let(:csv) { CSV.parse(csv_str) }
    let(:csv_str) { 10.times.map(&:to_s).join("\n") }
    let(:num_chunks) { 2 }
    let(:ranges) { subject.ranges_for(csv) }

    it 'breaks the main array into the correct number of ranges' do
      expect(ranges.count).to eq(2)
    end

    it 'returns the correct ranges' do
      expect(ranges[0]).to eq(0..4)
      expect(ranges[1]).to eq(5..9)
    end

    context 'when num_chunks does not evenly divide the array length' do
      let(:num_chunks) { 3 }

      it 'breaks the main array into the correct number of ranges' do
        expect(ranges.count).to eq(3)
      end

      it 'returns balanced sized ranges' do
        ranges.each do |range|
          expect(range.count).to be_between(3, 4)
        end
      end

      it 'includes all rows with no overlap' do
        flattened_range = [*ranges[0], *ranges[1], *ranges[2]]
        expect(flattened_range).to eq((0...10).to_a)
      end
    end
  end
end
