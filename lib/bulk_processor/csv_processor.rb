require_relative 'no_op_handler'
require_relative 'no_op_post_processor'

class BulkProcessor
  # An abstract implmentation of the CSVProcessor role. Provides
  #
  #   * A default implementation of `.optional_columns`, returning []
  #   * An initializer that assigns the arguments as instance attributes
  #   * An implementation of #start to cover a common use case
  #
  # The common use case cover by this class' implementation of `#start` is
  #
  #   1. Iteratively process each record
  #   2. Accumulate the results (did the processing succeed? what were the error
  #      messages?)
  #   3. Send the results to an instance of the Handler role.
  #
  # This class adds 2 required class methods that can be overridden in any
  # subclass
  #
  #   * row_processor_class - (required) Returns the class that implements the
  #     RowProcessor role to process rows of the CSV
  #   * handler_class - (optional) Returns the class that implements the Handler
  #     role,  which handles results from the completion (or failure) of
  #     processing the entire CSV.
  #
  # The `required_columns` method must still be implemented in a subclass
  #
  class CSVProcessor
    # @return [RowProcessor] a class that implements the RowProcessor interface
    def self.row_processor_class
      raise NotImplementedError,
            "#{self.class.name} must implement #{__method__}"
    end

    # @return [Handler] a class that implements the Handler role
    def self.handler_class
      NoOpHandler
    end

    # @return [PostProcessor] a class that implements the PostProcessor role
    def self.post_processor_class
      NoOpPostProcessor
    end

    # @return [Array<String>] column headers that must be present
    def self.required_columns
      raise NotImplementedError,
            "#{self.class.name} must implement #{__method__}"
    end

    # @return [Array<String>] column headers that may be present. If a column
    #   header is present that is not in 'required_columns' or
    #   'optional_columns', the file will be considered invalid and no rows will
    #   be processed.
    def self.optional_columns
      []
    end

    def initialize(records, payload: {})
      @records = records
      @payload = payload
      @successes = {}
      @errors = {}
    end

    # Iteratively process each record, accumulate the results, and pass those
    # off to the handler. If an unrescued error is raised for any record,
    # processing will halt for all remaining records and the `#fail!` will be
    # invoked on the handler.
    def start
      row_processors = records.map(&method(:row_processor))
      row_processors.each_with_index do |processor, index|
        processor.process!
        if processor.success?
          successes[index] = processor.messages
        else
          errors[index] = processor.messages
        end
      end
      self.class.post_processor_class.new(row_processors).start
      handler.complete!
    rescue Exception => exception
      handler.fail!(exception)

      # Swallow any StandardError, since we are already reporting it to the
      # user. However, we must re-raise Exceptions, such as SIGTERMs since they
      # need to be handled at a level above this gem.
      raise unless exception.is_a?(StandardError)
    end

    private

    attr_reader :records, :payload, :successes, :errors

    def handler
      self.class.handler_class.new(payload: payload, successes: successes,
                                   errors: errors)
    end

    def row_processor(record)
      self.class.row_processor_class.new(record, payload: payload)
    end
  end
end
