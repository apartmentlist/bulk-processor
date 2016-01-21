class BulkProcessor
  module BackEnd
    class << self
      def start(processor_class:, payload:, file_class:, key:)
        back_end = back_end_class.new(
          processor_class: processor_class,
          payload: payload,
          file_class: file_class,
          key: key
        )
        back_end.start
      end

      private

      def back_end_class
        back_end = BulkProcessor.config.back_end
        classified = back_end.to_s.split('_').collect(&:capitalize).join
        BulkProcessor::BackEnd.const_get(classified)
      end
    end
  end
end
