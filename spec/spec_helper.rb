RSpec.configure do |config|
  config.around(:each) { |example| Timeout.timeout(1, &example) }
end

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec/' # Exclude RSpec files from coverage
  end
rescue LoadError
  $stderr.puts 'NOTE: SimpleCov is not installed'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'peribot'
