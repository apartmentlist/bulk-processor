require 'rake'

class BulkProcessor
  module BackEnd
    class GcpPods
      class ProcessCSVTask
        include Rake::DSL

        def install_task
          namespace :bulk_processor do
            desc 'Start processing a CSV file'
            task :start, [:processor_class, :payload, :key] => :environment do |_task, args|
              BulkProcessor::ProcessCSV.new(
                args[:processor_class].constantize,
                PayloadSerializer.deserialize(args[:payload]),
                args[:key]
              ).perform
            end
          end
        end
      end
    end
  end
end

BulkProcessor::BackEnd::GcpPods::ProcessCSVTask.new.install_task
