require 'rake'

class BulkProcessor
  class Tasks
    include Rake::DSL

    def install_tasks
      namespace :bulk_processor do
        desc 'Start processing a CSV file'
        task :start, [:processor_class, :payload, :key] => :environment do |_task, args|
          Job.new.perform(
            args[:processor_class],
            args[:payload],
            args[:key]
          )
        end
      end
    end
  end
end

BulkProcessor::Tasks.new.install_tasks
