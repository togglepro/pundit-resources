require "bundler/gem_tasks"
require "rspec/core/rake_task"
require_relative "spec/dummy/config/environment"
require "appraisal"

RSpec::Core::RakeTask.new(:spec)

Rails.application.load_tasks

task :default => :spec

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  task :default => :appraisal
end
