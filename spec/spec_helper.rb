require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bulk_processor'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

BulkProcessor.configure do |config|
  config.queue_adapter = :test
end
