require 'peribot/configuration'
require 'peribot/middleware'
require 'peribot/preprocessor'
require 'peribot/postprocessor'
require 'peribot/sender'
require 'peribot/services'
require 'peribot/version'

require 'concurrent'
require 'docile'
require 'yaml'

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

    reset_config_builder
  end

  # Retrieve a read-only object containing information read from the
  # configuration directory set via the configure method.
  def config
    @config_builder.value || (fail @config_builder.reason)
  end

  class << self
    private

    # (Re-)Set the Concurrent::Delay that is used to lazily build the Peribot
    # global configuration object.
    def reset_config_builder
      @config_builder = Concurrent::Delay.new do
        setup_config(@meta_config).freeze
      end
    end

    # Build the configuration object for this Peribot instance by reading all
    # of the files in the configuration directory and creating a hash out of
    # them.
    #
    # @param meta_config [Peribot::Configuration] The meta_config object
    def setup_config(meta_config)
      fail 'No config directory defined' unless meta_config.conf_directory

      files = Dir[File.join(meta_config.conf_directory, '*.conf')]
      files.reduce({}) do |config, file|
        basename = File.basename file, '.*'
        config.merge(basename => load_config_file(file))
      end
    end

    # Load a configuration file.
    #
    # @param file [String] The name of the file to load
    def load_config_file(file)
      YAML.load_file file
    end
  end
end
