require 'gcp_manager'
require 'rake'

class BulkProcessor
  module BackEnd
    class Gcp
      class SplitCSVTask
        include Rake::DSL

        def install_task
          namespace :bulk_processor_gcp_pods do
            desc 'Split a CSV file and process each piece'
            task :split, [:processor_class, :payload, :key, :num_chunks] => :environment do |_task, args|
              BulkProcessor::SplitCSV.new(
                args[:processor_class].constantize,
                PayloadSerializer.deserialize(args[:payload]),
                args[:key],
                args[:num_chunks].to_i
              ).perform
            end
          end
        end
      end
    end
  end
end

GcpManager.config.rake_map['split-bulk-processor'] = 'bulk_processor_gcp_pods:split'
BulkProcessor::BackEnd::Gcp::SplitCSVTask.new.install_task
