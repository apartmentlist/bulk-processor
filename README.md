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

Bulk processor requires the following configuration

```ruby
BulkProcessor.queue_adapter = <adapter>
```

The default is `:inline`, which skips queueing and processes synchronously. Since
this is backed by ActiveJob, all of the adapters in [ActiveJob::QueueAdapters]( http://api.rubyonrails.org/classes/ActiveJob/QueueAdapters.html ),
including `:resque`.

You will also need to supply a class for item processing and a class/module for completion handling.
The item processor instance must respond to the following messages:

```
class PetItemProcessor
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

  # Instantiate the processor with a single row from the CSV represented by
  # a Hash<String, String>
  def initialize(record_hash, payload)
    @record_hash = record_hash
    @payload = payload
    @messages = []
    @success = false
  end

  # Process the row, e.g. create a new record in the DB, send an email, etc
  def process!
    pet = Pet.new(record_hash)
    if pet.save
      @success = true
    else
      @messages = pet.errors.full_messages
    end
  end

  # @return [true|false] true iff the item was processed completely
  def success?
    @success
  end

  # @return [Array<String>] list of messages for this item to pass back to the
  #   completion handler.
  def messages
    @messages
  end
end
```

A completion handler must respond to the following messages

```ruby
module NotificationHandler
  # Handle full or partial processing of records. Unless there was a fatal
  # error, all row indexes will be present either successes or errors, but not
  # both.
  #
  # @param payload [Hash] the payload passed into 'BulkProcessor.process', can
  #   be used to pass metadata around, e.g. the email address to send a
  #   completion report to
  # @param successes [Hash<Fixnum, Array<String>>] keys are all successfully
  #   processed rows, indexed from 0 (row 1 in the CSV is index 0 in this hash)
  #   The values are arrays of messages the item processor generated for the row
  #   (may be empty), e.g. { 0 => [], 1 => ['pet ID = 22 created'] }
  # @param errors [Hash<Fixnum, Array<String>>] similar structure to successes,
  #   but rows that were not completed successfully.
  # @param fatal_error [StandardError] if nil, then all rows were processed,
  #   else the error that was raise is passed in here
  def self.complete(payload, successes, errors, fatal_error = nil)
    if fatal_error
      PetProcessorMailer.fail(payload['recipient'], successes, errors)
    else
      PetProcessorMailer.complete(payload['recipient'], successes, errors)
    end
  end
end
```

Requesting file processing

```ruby
processor = BulkProcessor.new(file_stream, PetItemProcessor, NotificationHandler, {recipient: current_user.email})
if processor.process
  # The job has been enqueued, go get a coffee and wait
else
  handle_invalid_file(processor.errors)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/apartmentlist/bulk-processor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
