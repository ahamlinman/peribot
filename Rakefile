require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Set up RSpec tasks
RSpec::Core::RakeTask.new(:spec)

# Set up Rubocop tasks
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

task default: [:spec, :rubocop]
