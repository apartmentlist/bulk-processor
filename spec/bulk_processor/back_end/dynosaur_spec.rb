describe BulkProcessor::BackEnd::Dynosaur do
  describe '.new' do
    it 'configures Dynosaur::Client::HerokuClient' do
      BulkProcessor::BackEnd::Dynosaur.new(
        processor_class: MockCSVProcessor,
        payload: {},
        key: 'file.csv'
      )
      expect(Dynosaur::Client::HerokuClient.api_key).to eq('test-api-key')
      expect(Dynosaur::Client::HerokuClient.app_name).to eq('test-app-name')
    end
  end

  describe '#start' do
    subject do
      BulkProcessor::BackEnd::Dynosaur.new(
        processor_class: MockCSVProcessor,
        payload: {},
        key: 'file.csv'
      )
    end

    let(:dyno) { instance_double(Dynosaur::Process::Heroku, start: true) }

    before do
      allow(Dynosaur::Process::Heroku).to receive(:new).and_return(dyno)
    end

    it 'initializes a Dynosaur dyno with the correct args' do
      args = {
        task: 'bulk_processor:start',
        args: ['MockCSVProcessor', '{}', 'file.csv']
      }
      expect(Dynosaur::Process::Heroku).to receive(:new).with(args).and_return(dyno)
      subject.start
    end

    it 'starts a Dynosaur dyno' do
      expect(dyno).to receive(:start)
      subject.start
    end
  end
end
