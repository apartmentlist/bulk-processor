require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bulk_processor'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

BulkProcessor.configure do |config|
  config.file_class = MockFile
  config.back_end = :active_job
  config.queue_adapter = :test
  config.temp_directory = File.dirname(File.dirname(__FILE__))
  config.aws.access_key_id = 'test-access-key-id'
  config.aws.secret_access_key = 'test-secret-access-key'
  config.aws.bucket = 'test-bucket'
  config.heroku.api_key = 'test-api-key'
  config.heroku.app_name = 'test-app-name'
end

ActiveJob::Base.logger.level = Logger::FATAL
