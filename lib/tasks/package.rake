REPO_NAME = 'bulk-processor'
MODULE_NAME = 'bulk_processor'

def adjust_module_name(str)
  str
end

namespace :package do
  require 'open3'
  require 'pathname'
  require 'active_support'
  require_relative "../#{MODULE_NAME}/version"

  repo_version = ActiveSupport::Inflector.constantize(
    "#{adjust_module_name(ActiveSupport::Inflector.classify(MODULE_NAME))}::VERSION"
  )
  root_dir = Pathname.new(File.join(__dir__, '..', '..')).expand_path
  output_filename = "pkg/#{REPO_NAME}-#{repo_version}.gem"

  desc 'Check a credential file for rubygem publishing'
  task :check_cred do
    path_cred = File.join(Dir.home, '.gem', 'credentials')
    raise "Credential file not found: #{path_cred}" unless File.exists?(path_cred)

    perm_cred = File.stat(path_cred).mode.to_s(8).split("")[-4..-1].join.to_s
    raise "File permission for credential should be 0600. Get #{perm_cred}" if perm_cred != '0600'

    puts 'Credential looks good'
  end

  desc 'Publish this package to github'
  task :publish_github do
    Rake::Task['package:check_cred'].invoke
    Rake::Task['build'].invoke

    stdout, stderr, status = Open3.capture3(
      "gem push --key github --host https://rubygems.pkg.github.com/apartmentlist #{output_filename}",
      { chdir: root_dir }
    )
    unless status.success?
      puts "OUT: #{stdout}"
      puts "ERR: #{stderr}"
      raise 'Failed to publish gem'
    end

    puts stdout
    puts "#{output_filename} is now published at GitHub. Checkout https://github.com/apartmentlist/#{REPO_NAME}/packages/"
  end
end
