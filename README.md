![Travis status for apartmentlist/bulk-processor](https://travis-ci.org/apartmentlist/bulk-processor.svg?branch=master)


# BulkProcessor

Bulk upload data in a file (e.g. CSV), process in the background, then send a
success or failure report

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bulk-processor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bulk-processor

## Usage

### Configuration

Bulk processor requires the following configuration

#### Back end: ActiveJob

Include the `activejob` and back-end queueing gems in your Gemfile, e.g.

```ruby
# Gemfile
gem 'activejob'
gem 'bulk-processor'
gem 'resque'
```

```ruby
BulkProcessor.back_end = :active_job
BulkProcessor.queue_adapter = <adapter>
```

The default queue_adapter is `:inline`, which skips queueing and processes synchronously. Since
this is backed by ActiveJob, all of the adapters in [ActiveJob::QueueAdapters]( http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html ) are supported,
including `:resque`.

#### Back end: Dynosaur

Include the `dynosau` gem in your Gemfile, e.g.

```ruby
# Gemfile
gem 'dynosaur'
gem 'resque'
```

```ruby
BulkProcessor.back_end = :dynosaur
BulkProcessor.heroku.api_key = 'my-heroku-api-key'
BulkProcessor.heroku.app_name = 'my-heroku-app-name'
```

```ruby
# Rakefile
require 'bulk_processor/tasks'
```

#### AWS S3

```ruby
BulkProcessor.temp_directory = '/tmp'
BulkProcessor.aws.access_key_id = 'my-aws-access-key'
BulkProcessor.aws.secret_access_key = 'my-aws-secret'
BulkProcessor.aws.bucket = 'my-s3-bucket'
```

The CSV file passed to BulkProcessor will be persisted on AWS S3 so that the job
can access it. This requires configuring AWS credentials, the S3 bucket in which
to store the file, and a local temp directory to hold the file locally.

### Setting up the processor

You will need to supply a class for CSV processing. This class must respond to the
`start` instance method, the `required_columns` and `optional_columns` class methods,
and have the following signature for initialize:

```ruby
class PetCSVProcessor
  # @return [Array<String>] column headers that must be present
  def self.required_columns
    ['species', 'name', 'age']
  end

  # @return [Array<String>] column headers that may be present. If a column
  #   header is present that is not in 'required_columns' or 'optional_columns',
  #   the file will be considered invalid and no rows will be processed.
  def self.optional_columns
    ['favorite_toy', 'talents']
  end

  def initialize(csv, payload:)
    # Assign instance variables and do any other setup
  end

  def start
    # Process the CSV
  end
end
```

#### Swiss Army Knife base class

To account for a common use case, a base `BulkProcessor::CSVProcessor` class is provided,
though it must be explicitly required. This base class can be subclassed to build a CSV processor.
This base class implements the initializer and `#start` methods and returns an empty set for `.optional_columns`.

The `#start` method iterates over each row, processes it using a `RowProcessor`,
accumulates the results, which are passed off to a `Handler`. An example
implementation could look like:

```ruby
require 'bulk_processor/csv_processor'

class PetCSVProcessor < BulkProcessor::CSVProcessor
  # Note: this must be overridden in a subclass
  #
  # @return [Array<String>] column headers that must be present
  def self.required_columns
    ['species', 'name', 'age']
  end

  # @return [Array<String>] column headers that may be present. If a column
  #   header is present that is not in 'required_columns' or 'optional_columns',
  #   the file will be considered invalid and no rows will be processed.
  def self.optional_columns
    ['favorite_toy', 'talents']
  end

  # Note: this must be overridden in a subclass
  #
  # @return [RowProcessor] a class that implements the RowProcessor role
  def self.row_processor_class
    PetRowProcessor
  end

  # @return [PostProcessor] a class that implements the PostProcessor role
  def self.post_processor_class
    PetPostProcessor
  end

  # @return [Handler] a class that implements the Handler role
  def self.handler_class
    PetHandler
  end
end
```

```ruby
class PetRowProcessor < BulkProcessor::CSVProcessor::RowProcessor
  # Process the row, e.g. create a new record in the DB, send an email, etc
  def process!
    pet = Pet.new(row)
    if pet.save
      self.successful = true
    else
      messages.concat(pet.errors.full_messages)
    end
  end

  # Setting these allow us to identify error messages by these key/values for
  # a row, rather than using the row number
  def primary_keys
    ['species', 'name']
  end
end
```

```ruby
class PetPostProcessor
  attr_reader :results

  def initialize(row_processors)
    # Assign instance variables and do any other setup
  end

  def start
    cat_count = 0
    @results = []
    row_processors.each do |row_processor|
      cat_count += 1 if row_processor.cat?
    end

    if cat_count > 2
      @results << BulkProcessor::CSVProcessor::Result.new(messages: ['Too many cats!'],
                                                          successful: false)
    end
  end
end
```

```ruby
class PetHandler
  # @param payload [Hash] the payload passed into 'BulkProcessor.process', can
  #   be used to pass metadata around, e.g. the email address to send a
  #   completion report to
  # @param results [Array<BulkProcessor::CSVProcessor::RowProcessor>] results
  #   for processing the rows (there will be one pre row in the CSV plus zero
  #   or more from post-processing)
  def initialize(payload:, results:)
    # Assign instance variables and do any other setup
  end

  # Notify the owner that their pets were processed
  def complete!
    OwnerMailer.completed(results, payload)
  end

  # Notify the owner that processing failed
  #
  # @param fatal_error [StandardError] if nil, then all rows were processed,
  #   else the error that was raise is passed in here
  def fail!(fatal_error)
    OwnerMailer.failed(fatal_error, payload)
  end
end
```

### Kicking off the process

```ruby
processor = BulkProcessor.new(
              key: file_name,
              stream: file_stream,
              processor_class: PetCSVProcessor,
              payload: { recipient: current_user.email }
            )
if processor.start
  # The job has been enqueued, go get a coffee and wait
else
  # Something went wrong, alert the file uploader
  handle_invalid_file(processor.errors)
end
```

#### Parallelization

For larger CSV files, you may wish to process rows in parallel. This gem allows
you to scale up to an arbitrary number of parallel processes by providing an optional
argument to `#start`. Doing this will cause the input CSV file to be split into
*N* number of smaller CSV files, each one being processed in separate processes.
It is important to note that the file *must* be sorted by the boundary column for
it to deliver on its promise.

```ruby
processor = BulkProcessor.new(
              key: file_name,
              stream: file_stream,
              processor_class: PetCSVProcessor,
              payload: { recipient: current_user.email }
            )
if processor.start(5)
  # Split the main CSV into 5 smaller files and process in parallel.
else
  # Something went wrong, alert the file uploader
  handle_invalid_file(processor.errors)
end
```

By default, the file will be split into equal-sized partitions. If you need the partitions
to keep all rows with the same value for a column into the same partition, define `.boundary_column`
on the processor class to return the name of that column. E.g.

```csv
pet_id,meal,mead_date
1,kibble,2015-11-02
1,bits,2015-11-03
...
1,alpo,2015-12-31
2,alpo,2015-11-01
...
```

```ruby
class PetCSVProcessor
  def self.boundary_column
    'pet_id'
  end
  ...
end
```

Finally, to be notified of any failures in the splitting process, you can define
`.handler_class` on your processor class to return a class that implements the Handler role.
If an error is raised in the splitting, `#fail!` will be called on the Handler with
the error.

```ruby
class PetCSVProcessor
  def self.handler_class
    PetHandler
  end
  ...
end
```

### BulkProcessor::CSVProcessor::Result

The result instances passed from BulkProcessor::CSVProcessor to the Handler
respond to the following messages:

* `#messages [Array<String>]` - zero or more messages generated when processing the row
* `#row_num [Fixnum|nil]` - the CSV row number (starting with 2) or nil if result is from post-processing
* `#primary_attributes [Hash]` - a set of values that can be used to identify which row the messages are for.
You must override `#primary_keys` to use this.
* `#successful?` - true iff the processing happened with no errors

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/apartmentlist/bulk-processor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
