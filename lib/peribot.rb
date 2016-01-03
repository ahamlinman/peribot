require 'peribot/configuration'
require 'peribot/middleware'
require 'peribot/preprocessor'
require 'peribot/postprocessor'
require 'peribot/sender'
require 'peribot/services'
require 'peribot/version'

require 'docile'

# The top-level namespace for Peribot. Some global functionality is also
# provided as part of this module.
module Peribot
  class << self
    attr_reader :meta_config
  end

  module_function

  # A simple logging function for use by Peribot components. Outputs the given
  # message to stderr with a "[Peribot]" prefix.
  #
  # @param message Text to output to stderr
  def log(message)
    $stderr.puts "[Peribot] #{message}"
  end

  # Execute a DSL to configure a Peribot instance. This is used to set
  # directories for configuration and persistent store files.
  def configure(&block)
    builder = Peribot::Configuration::Builder.new
    @meta_config = Docile.dsl_eval(builder, &block).build
  end
end
