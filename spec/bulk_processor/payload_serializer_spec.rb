describe BulkProcessor::PayloadSerializer do
  describe '.serialize' do
    it 'converts { "a" => "b" } to "a=b"' do
      expect(BulkProcessor::PayloadSerializer.serialize('a' => 'b'))
        .to eq('a=b')
    end

    it 'converts { "a" => "b", "c" => "d" } to "a=b&c=d"' do
      expect(BulkProcessor::PayloadSerializer.serialize('a' => 'b', 'c' => 'd'))
        .to eq('a=b&c=d')
    end
  end

  describe '.deserialize' do
    it 'returns { "a" => "b" } from "a=b"' do
      expect(BulkProcessor::PayloadSerializer.deserialize('a=b'))
        .to eq('a' => 'b')
    end

    it 'returns { "a" => "b", "c" => "d" } from "a=b&c=d"' do
      expect(BulkProcessor::PayloadSerializer.deserialize('a=b&c=d'))
        .to eq('a' => 'b', 'c' => 'd')
    end
  end
end
