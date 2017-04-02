begin
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec/' # Exclude RSpec files from coverage
  end
rescue LoadError
  $stderr.puts 'NOTE: SimpleCov is not installed'
end

require 'rspec/eventually'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'peribot'
