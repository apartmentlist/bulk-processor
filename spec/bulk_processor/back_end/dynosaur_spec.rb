# frozen_string_literal: true

require 'bulk_processor/back_end/dynosaur'

describe BulkProcessor::BackEnd::Dynosaur do
  it_behaves_like 'a role', 'BackEnd'

  describe '.new' do
    it 'configures Dynosaur::Client::HerokuClient' do
      BulkProcessor::BackEnd::Dynosaur.new(
        processor_class: MockCSVProcessor,
        payload: { 'foo' => 'bar' },
        key: 'file.csv',
        job: 'start-dynosaur-test'
      )
      expect(Dynosaur::Client::HerokuClient.api_key).to eq('test-api-key')
      expect(Dynosaur::Client::HerokuClient.app_name).to eq('test-app-name')
    end
  end

  describe '#start' do
    subject do
      BulkProcessor::BackEnd::Dynosaur.new(
        processor_class: MockCSVProcessor,
        payload: { 'foo' => 'bar' },
        key: 'file.csv',
        job: nil
      )
    end

    let(:dyno) { instance_double(Dynosaur::Process::Heroku, start: true) }

    before do
      allow(Dynosaur::Process::Heroku).to receive(:new).and_return(dyno)
    end

    it 'initializes a Dynosaur dyno with the correct args' do
      args = {
        task: 'bulk_processor:start',
        args: ['MockCSVProcessor', 'foo=bar', 'file.csv']
      }
      expect(Dynosaur::Process::Heroku).to receive(:new).with(args).and_return(dyno)
      subject.start
    end

    it 'starts a Dynosaur dyno' do
      expect(dyno).to receive(:start)
      subject.start
    end
  end

  describe '#split' do
    subject do
      BulkProcessor::BackEnd::Dynosaur.new(
        processor_class: MockCSVProcessor,
        payload: { 'foo' => 'bar' },
        key: 'file.csv',
        job: nil
      )
    end

    let(:dyno) { instance_double(Dynosaur::Process::Heroku, start: true) }

    before do
      allow(Dynosaur::Process::Heroku).to receive(:new).and_return(dyno)
    end

    it 'initializes a Dynosaur dyno with the correct args' do
      args = {
        task: 'bulk_processor:split',
        args: ['MockCSVProcessor', 'foo=bar', 'file.csv', '2']
      }
      expect(Dynosaur::Process::Heroku).to receive(:new).with(args).and_return(dyno)
      subject.split(2)
    end

    it 'starts a Dynosaur dyno' do
      expect(dyno).to receive(:start)
      subject.split(2)
    end
  end
end
