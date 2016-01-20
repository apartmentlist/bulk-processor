describe BulkProcessor::S3File do
  subject { BulkProcessor::S3File.new(key) }

  let(:aws_credentials) { instance_double(Aws::Credentials) }
  let(:bucket) { BulkProcessor.config.aws.bucket }
  let(:key) { 'files/1/data.txt' }
  let(:s3_client) { instance_double(Aws::S3::Client) }

  before do
    allow(Aws::Credentials).to receive(:new).with(
      BulkProcessor.config.aws.access_key_id,
      BulkProcessor.config.aws.secret_access_key
    ).and_return(aws_credentials)
    allow(Aws::S3::Client).to receive(:new).with(credentials: aws_credentials)
      .and_return(s3_client)
  end

  describe '#write' do
    let(:contents) { 'datum,datum,datum,date-him,datum,datum' }
    let(:public_url) { 'http://file.url' }
    let(:s3_bucket) { instance_double(Aws::S3::Bucket) }
    let(:s3_resource) { instance_double(Aws::S3::Resource) }
    let(:s3_object) do
      instance_double(Aws::S3::Object, public_url: public_url, put: true)
    end

    before do
      allow(Aws::S3::Resource).to receive(:new).with(client: s3_client)
        .and_return(s3_resource)
      allow(s3_resource).to receive(:bucket).with(bucket).and_return(s3_bucket)
      allow(s3_bucket).to receive(:object).with(key).and_return(s3_object)
    end

    it 'writes to the bucket' do
      expect(s3_resource).to receive(:bucket).with(bucket).and_return(s3_bucket)
      subject.write(contents)
    end

    it 'puts the contents in the file' do
      expect(s3_object).to receive(:put).with(body: contents)
      subject.write(contents)
    end

    it 'returns the public_url of the new object' do
      expect(subject.write(contents)).to eq(public_url)
    end
  end

  describe '#read' do
    it 'gets the object from the bucket with the correct key' do
      expect(s3_client).to receive(:get_object)
        .with({ bucket: bucket, key: key }, anything)
      subject.read {}
    end

    it 'yields a local copy of the remote file' do
      def s3_client.get_object(_config, opts)
        opts[:target].write('test file contents')
      end

      yielded_contents = 'deadbeef'
      subject.read do |file|
        yielded_contents = file.read
      end
      expect(yielded_contents).to eq('test file contents')
    end
  end

  describe '#exists?' do
    before { allow(s3_client).to receive(:get_object) }

    context 'when the file exists' do
      it 'returns true' do
        expect(subject.exists?).to eq(true)
      end
    end

    context 'when the file does not exist' do
      before do
        error = Aws::S3::Errors::NoSuchKey.new('arg1', 'arg2')
        allow(s3_client).to receive(:get_object).and_raise(error)
      end

      it 'returns false' do
        expect(subject.exists?).to eq(false)
      end
    end
  end

  describe '.delete_file' do
    it 'gets the object from the bucket with the correct key' do
      expect(s3_client).to receive(:delete_object).with(bucket: bucket, key: key)
      subject.delete
    end
  end
end
