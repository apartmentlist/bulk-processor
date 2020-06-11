require 'gcp_manager'
require 'rake'

class BulkProcessor
  module BackEnd
    class Gcp
      class ProcessCSVTask
        include Rake::DSL

        def install_task
          namespace :bulk_processor_gcp_pods do
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

GcpManager.add_task('start-bulk-processor', 'rake bulk_processor_gcp_pods:start')
BulkProcessor::BackEnd::Gcp::ProcessCSVTask.new.install_task
