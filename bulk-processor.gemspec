# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bulk_processor/version'

Gem::Specification.new do |spec|
  spec.name          = 'bulk-processor'
  spec.version       = BulkProcessor::VERSION
  spec.authors       = ['Tom Collier, Justin Richard']
  spec.email         = ['collier@apartmentlist.com, justin@apartmentlist.com']

  spec.summary       = 'Background process CSV data'
  spec.description   = <<-DESC
Bulk upload data in a file (e.g. CSV), process in the background, then send a
success or failure report
                       DESC
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.1'

  spec.dependency 'activejob'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
