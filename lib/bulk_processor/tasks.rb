require 'rake'

class BulkProcessor
  class Tasks
    include Rake::DSL

    def install_tasks
      namespace :bulk_processor do
        desc 'Start processing a CSV file'
        task :start, [:processor_class, :payload, :key] => :environment do |_task, args|
          Job::ProcessCSV.new.perform(
            args[:processor_class],
            args[:payload],
            args[:key]
          )
        end

        desc 'Split a CSV file'
        task :split, [:processor_class, :payload, :key, :num_chunks] => :environment do |_task, args|
          Job::SplitCSV.new.perform(
            args[:processor_class],
            args[:payload],
            args[:key],
            args[:num_chunks]
          )
        end
      end
    end
  end
end

BulkProcessor::Tasks.new.install_tasks
