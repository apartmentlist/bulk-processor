describe BulkProcessor::RowChunker::Boundary do
  it_behaves_like 'a role', 'RowChunker'

  describe '#ranges_for' do
    subject do
      BulkProcessor::RowChunker::Boundary.new(2, boundary_column: 'user_id')
    end

    let(:csv) { CSV.parse(csv_str, headers: true) }
    let(:ranges) { subject.ranges_for(csv) }

    context 'when values differ on either side of the balanced boundary' do
      let(:csv_str) do
        %w[
          user_id
          1
          2
          3
          4
          5
          6
        ].join("\n")
      end

      it 'breaks the main array into the correct number of ranges' do
        expect(ranges.count).to eq(2)
      end

      it 'returns the correct ranges' do
        expect(ranges[0]).to eq(0..2)
        expect(ranges[1]).to eq(3..5)
      end
    end

    context 'when values are the same on either side of a balanced boundary' do
      let(:csv_str) do
        %w[
          user_id
          1
          2
          3
          3
          4
          5
        ].join("\n")
      end

      it 'breaks the main array into the correct number of ranges' do
        expect(ranges.count).to eq(2)
      end

      it 'returns ranges that do not break up the boundary_column' do
        expect(ranges[0]).to eq(0..3)
        expect(ranges[1]).to eq(4..5)
      end
    end
  end
end
