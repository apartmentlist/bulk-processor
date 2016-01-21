describe BulkProcessor::CSVProcessor::RowProcessor do
  it_behaves_like 'a role', 'RowProcessor'

  class TestRowProcessor < BulkProcessor::CSVProcessor::RowProcessor
    def process!
      case row['name']
      when 'Bob'
        self.successful = true
      when 'Fred'
        messages << "He's not Bob"
        self.successful = false
      end
    end

    def primary_keys
      %w[name ssn]
    end
  end

  describe '#result' do
    subject do
      row = { 'name' => name, 'ssn' => '0' }
      TestRowProcessor.new(row, row_num: 3, payload: {})
    end

    let(:name) { 'Fred' }

    before { subject.process! }

    it 'includes any messsages' do
      expect(subject.result.messages).to include("He's not Bob")
    end

    it 'includes the row num' do
      expect(subject.result.row_num).to eq(3)
    end

    it 'includes the primary attributes' do
      expect(subject.result.primary_attributes).to eq('name' => 'Fred', 'ssn' => '0')
    end

    context 'when successful is explicitly set to true during processing' do
      let(:name) { 'Bob' }

      it 'is successful' do
        expect(subject.result).to be_successful
      end
    end

    context 'when successful is explicitly set to false during processing' do
      it 'is not successful' do
        expect(subject.result).to_not be_successful
      end
    end

    context 'when successful is untouched during processing' do
      let(:name) { 'Randy' }

      it 'is not successful' do
        expect(subject.result).to_not be_successful
      end
    end
  end
end
