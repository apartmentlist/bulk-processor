require 'aws-sdk-s3'

class BulkProcessor
  # Read and write files in a pre-configured S3 bucket.
  class S3File
    NAMESPACE = 'bulk_processor'.freeze
    private_constant :NAMESPACE

    # @param key [String] the unique identifier (within the bucket) used to
    #   access the file
    def initialize(key)
      @key = "#{NAMESPACE}/#{key}"
    end

    def exists?
      client.get_object(bucket: bucket, key: key)
      true
    rescue Aws::S3::Errors::NoSuchKey
      false
    end

    # Yield the file stored in the bucket identified by the key. The file is
    # only guaranteed to exist locally within the block, any attempts to access
    # the file outside of the block will fail.
    #
    # @yields [File] a local copy of the remote file
    def open
      begin
        with_temp_file do |local_file|
          object = client.get_object(bucket: bucket, key: key)
          local_file.write(object.body.read)
          local_file.rewind
          yield local_file
        end
      rescue Aws::S3::Errors => e
        puts "Aws::S3::Errors: #{e}, KEY: #{key}, BUCKET: #{bucket}"
        raise
      end
    end

    # Write a new file to the bucket on S3
    #
    # @param contents [String] the contents of the file to create
    # @return [String] the URL of the new file
    def write(contents)
      retry_limit = 3
      remote_file = resource.bucket(bucket).object(key)
      begin
        remote_file.put(body: contents)
        client.get_object(bucket: bucket, key: key)
      rescue Aws::S3::Errors::NoSuchKey => e
        if retry_limit > 0
          retry_limit -= 1
          retry
        end
        raise e
      end
      remote_file.public_url
    end

    def delete
      client.delete_object(bucket: bucket, key: key)
    end

    private

    attr_reader :bucket, :key

    def bucket
      BulkProcessor.config.aws.bucket || raise('AWS bucket must be set in the config')
    end

    def access_key_id
      BulkProcessor.config.aws.access_key_id || raise('AWS access_key_id must be set in the config')
    end

    def secret_access_key
      BulkProcessor.config.aws.secret_access_key || raise('AWS secret_access_key must be set in the config')
    end

    def resource
      Aws::S3::Resource.new(client: client)
    end

    def client
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      Aws::S3::Client.new(credentials: credentials)
    end

    def with_temp_file
      base_dir = Pathname.new(BulkProcessor.config.temp_directory)
      file = Tempfile.new('aws_utils', base_dir)
      yield file
    ensure
      file.close if file && !file.closed?
      file.try(:unlink)
    end
  end
end
