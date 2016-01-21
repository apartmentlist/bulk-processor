require 'rack'
require 'uri'

class BulkProcessor
  # The payload must be serialized to be command line friendly (since Dynosaur
  # runs a rake task with command-line args)
  module PayloadSerializer
    class << self
      # @param payload [Hash] the client payload to be passed into the processing
      #   job and ultimately the handler
      # @return [String] a serialized version of the string that can be passed
      #   to any of the back-ends
      def serialize(payload)
        URI.encode_www_form(payload)
      end

      # @param payload [String] a serialized version of the payload
      # @return [Hash] the original Hash payload (with all keys and values
      #   stringified)
      def deserialize(string)
        Rack::Utils.parse_nested_query(string)
      end
    end
  end
end
