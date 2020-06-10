# frozen_string_literal: true

require 'dynosaur'

require_relative 'dynosaur/tasks'

class BulkProcessor
  module BackEnd
    # Execute jobs via rake tasks that will spawn a new Heroku dyno
    class Dynosaur
      def initialize(processor_class:, payload:, key:, job:)
        @processor_class = processor_class.name
        @payload = PayloadSerializer.serialize(payload)
        @key = key
        @job = job || nil
        configure_dynosaur
      end

      def start
        args = {
          task: 'bulk_processor:start',
          args: [processor_class, payload, key]
        }
        ::Dynosaur::Process::Heroku.new(args).start
      end

      def split(num_processes)
        args = {
          task: 'bulk_processor:split',
          args: [processor_class, payload, key, num_processes.to_s]
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
