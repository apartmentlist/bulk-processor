require 'dynosaur'

class BulkProcessor
  module BackEnd
    class Dynosaur
      def initialize(processor_class:, payload:, key:)
        @processor_class = processor_class
        @payload = payload
        @key = key
        configure_dynosaur
      end

      def start
        args = {
          task: 'bulk_processor:start',
          args: [
            processor_class.name,
            PayloadSerializer.serialize(payload),
            key
          ]
        }
        ::Dynosaur::Process::Heroku.new(args).start
      end

      private

      attr_reader :processor_class, :payload, :key

      def configure_dynosaur
        ::Dynosaur::Client::HerokuClient.configure do |config|
          config.api_key = BulkProcessor.config.heroku.api_key
          config.app_name = BulkProcessor.config.heroku.app_name
        end
      end
    end
  end
end
