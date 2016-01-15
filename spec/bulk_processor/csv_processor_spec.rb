require 'bulk_processor/csv_processor'

describe BulkProcessor::CSVProcessor do
  class TestCSVProcessor < BulkProcessor::CSVProcessor
  end

  before do
    allow(TestCSVProcessor).to receive(:row_processor_class)
      .and_return(MockRowProcessor)
    allow(TestCSVProcessor).to receive(:handler_class).and_return(MockHandler)
  end

  it_behaves_like 'a role', 'CSVProcessor'

  describe '#start' do
    subject { TestCSVProcessor.new(records, payload: payload) }

    let(:records) { [{ 'name' => 'Rex' }, { 'name' => 'Fido' }] }
    let(:payload) { { 'relevant' => 'data' } }
    let(:row_processor_1) do
      instance_double(BulkProcessor::Role::RowProcessor, process!: true,
                                                         success?: true,
                                                         messages: [])
    end
    let(:row_processor_2) do
      instance_double(BulkProcessor::Role::RowProcessor, process!: true,
                                                         success?: true,
                                                         messages: [])
    end

    before do
      allow(MockRowProcessor).to receive(:new)
        .with({ 'name' => 'Rex' }, payload: payload)
        .and_return(row_processor_1)
      allow(MockRowProcessor).to receive(:new)
        .with({ 'name' => 'Fido' }, payload: payload)
        .and_return(row_processor_2)
      allow(MockHandler).to receive(:complete)
    end

    it 'processes all records' do
      expect(row_processor_1).to receive(:process!)
      expect(row_processor_2).to receive(:process!)
      subject.start
    end
  end
end
