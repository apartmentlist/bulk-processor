describe BulkProcessor::ValidatedCSV do
  subject { BulkProcessor::ValidatedCSV.new(stream, ['name'], ['age']) }

  let(:stream) { StringIO.new(csv_str) }

  context 'with valid headers' do
    let(:csv_str) { "name,age\nRex,1" }

    it 'is valid' do
      expect(subject).to be_valid
    end

    it 'returns the correct row_hashes' do
      expect(subject.row_hashes).to eq([{ 'name' => 'Rex', 'age' => '1' }])
    end
  end

  context 'with a missing optional header' do
    let(:csv_str) { "name\nRex" }

    it 'is valid' do
      expect(subject).to be_valid
    end

    it 'returns the correct row_hashes' do
      expect(subject.row_hashes).to eq([{ 'name' => 'Rex' }])
    end
  end

  context 'with an unknown header' do
    let(:csv_str) { "name,owner\nRex,Margo" }

    it 'is not valid' do
      expect(subject).to_not be_valid
    end

    it 'provides a useful error message' do
      subject.valid?
      expect(subject.errors).to include('Unrecognized column(s) found: owner')
    end
  end

  context 'with a missing required header' do
    let(:csv_str) { "age\n1" }

    it 'is not valid' do
      expect(subject).to_not be_valid
    end

    it 'provides a useful error message' do
      subject.valid?
      expect(subject.errors).to include('Missing required column(s): name')
    end
  end

  context 'with blank header' do
    let(:csv_str) { ",name\n1,Rex" }

    it 'is not valid' do
      expect(subject).to_not be_valid
    end

    it 'provides a useful error message' do
      subject.valid?
      expect(subject.errors)
        .to include('Missing or malformed column header, is one of them blank?')
    end

    it 'has empty row_hashes' do
      expect(subject.row_hashes).to eq([])
    end
  end
end
