require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  Rake.add_rakelib('./lib/tasks')

  task default: :spec
rescue LoadError
  # no rspec available
end

