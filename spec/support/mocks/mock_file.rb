require 'fileutils'

# Injectable file storage module to use instead of S3File in specs
class MockFile
  TMP_PATH_PARTS = %w[tmp mockfs]
  private_constant :TMP_PATH_PARTS

  # Use this to manually clean up after each spec that creates a file
  def self.cleanup
    FileUtils.rm_rf(base_dir.join(*TMP_PATH_PARTS))
  end

  def self.base_dir
    Pathname.new(BulkProcessor.config.temp_directory)
  end

  def initialize(key)
    @key = key
  end

  def write(contents)
    dir_path = self.class.base_dir.join(*TMP_PATH_PARTS, *key.split('/')[0..-2])
    FileUtils.mkdir_p(dir_path)
    File.open(full_path, 'w') do |file|
      file.write(contents)
    end
    full_path
  end

  def read
    raise 'File does not exist' unless exists?
    with_temp_file do |local_file|
      File.open(full_path, 'r') do |file|
        local_file.write(file.read)
        local_file.rewind
        yield local_file
      end
    end
  end

  def exists?
    File.exist?(full_path)
  end

  def delete
    FileUtils.rm_f(full_path)
  end

  private

  attr_reader :key

  def full_path
    self.class.base_dir.join(*TMP_PATH_PARTS, *key.split('/'))
  end

  def with_temp_file
    file = Tempfile.new('test_file_storage', self.class.base_dir.join('tmp'))
    yield file
  ensure
    file.close if file && !file.closed?
    file.try(:unlink)
  end
end
