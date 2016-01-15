describe BulkProcessor::StreamEncoder do
  describe '#encoded' do
    subject { BulkProcessor::StreamEncoder.new(stream) }

    let(:stream) { StringIO.new("yen=\xA5") }

    it 'strips non-UTF-8 characters from the stream' do
      expect(subject.encoded).to eq('yen=')
    end
  end
end
