require 'dynosaur'

class BulkProcessor
  module BackEnd
    class Dynosaur
      def initialize(processor_class:, payload:, file_class:, key:)
        @processor_class = processor_class
        @payload = payload
        @file_class = file_class
        @key = key
        configure_dynosaur
      end

      def start
        args = {
          task: 'bulk_processor:start',
          args: [processor_class.name, payload.to_json, file_class.name, key]
        }
        ::Dynosaur::Process::Heroku.new(args).start
      end

      private

      attr_reader :processor_class, :payload, :file_class, :key

      def configure_dynosaur
        ::Dynosaur::Client::HerokuClient.configure do |config|
          config.api_key = BulkProcessor.config.heroku.api_key
          config.app_name = BulkProcessor.config.heroku.app_name
        end
      end
    end
  end
end
