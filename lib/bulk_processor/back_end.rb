# frozen_string_literal: true

class BulkProcessor
  module BackEnd
    class << self
      def start(processor_class:, payload:, key:, num_processes: 1, job:)
        back_end = back_end_class.new(
          processor_class: processor_class,
          payload: payload,
          key: key,
          job: job
        )
        num_processes > 1 ? back_end.split(num_processes) : back_end.start
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
