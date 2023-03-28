require_relative 'csv_processor/no_op_handler'
require_relative 'csv_processor/no_op_post_processor'
require_relative 'csv_processor/no_op_pre_processor'
require_relative 'csv_processor/no_op_cleanup_processor'
require_relative 'csv_processor/result'
require_relative 'csv_processor/row_processor'

class BulkProcessor
  # An abstract implmentation of the CSVProcessor role. Provides
  #
  #   * A default implementation of `.optional_columns`, returning []
  #   * An initializer that assigns the arguments as instance attributes
  #   * An implementation of #start to cover a common use case
  #
  # The common use case cover by this class' implementation of `#start` is
  #
  #   1. Iteratively process each row
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
    # Since the first data column in a CSV is row 2, but will have index 0 in
    # the items array, we need to offset the index by 2 when we add a row
    # identifier to all error messages.
    FIRST_ROW_OFFSET = 2
    private_constant :FIRST_ROW_OFFSET

    # @return [RowProcessor] a class that implements the RowProcessor interface
    def self.row_processor_class
      raise NotImplementedError,
            "#{self.class.name} must implement #{__method__}"
    end

    # @return [Handler] a class that implements the Handler role
    def self.handler_class
      NoOpHandler
    end

    # @return [PreProcessor] a class that implements the PreProcessor role
    def self.pre_processor_class
      NoOpPreProcessor
    end

    def self.cleanup_processor_class
      NoOpCleanupProcessor
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

    def initialize(csv, payload: {})
      @payload = payload
      @row_processors = csv.map.with_index(&method(:row_processor))
      @results = []
    end

    # Iteratively process each row, accumulate the results, and pass those
    # off to the handler. If an unrescued error is raised for any row,
    # processing will halt for all remaining rows and the `#fail!` will be
    # invoked on the handler.
    def start
      pre_processes
      if self.class.pre_processor_class.fail_process_if_failed && results.present?
        handler.complete!
      else
        row_processors.each do |processor|
          processor.process!
          results << processor.result
        end
        post_processes
        cleanup
        handler.complete!
      end
    rescue Exception => exception
      handler.fail!(exception)

      # Swallow any StandardError, since we are already reporting it to the
      # user. However, we must re-raise Exceptions, such as SIGTERMs since they
      # need to be handled at a level above this gem.
      raise unless exception.is_a?(StandardError)
    end

    private

    attr_reader :row_processors, :payload, :results

    def handler
      self.class.handler_class.new(payload: payload, results: results)
    end

    def row_processor(row, index)
      row_num = index + FIRST_ROW_OFFSET
      self.class.row_processor_class.new(row, row_num: row_num, payload: payload)
    end

    def post_processes
      post_processor = self.class.post_processor_class.new(row_processors)
      post_processor.start
      results.concat(post_processor.results)
    end

    def pre_processes
      pre_processor = self.class.pre_processor_class.new(row_processors)
      pre_processor.start
      results.concat(pre_processor.results)
    end

    def cleanup
      cleanup_processor = self.class.cleanup_processor_class.new(row_processors)
      cleanup_processor.start
    end
  end
end
