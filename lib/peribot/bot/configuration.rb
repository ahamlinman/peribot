require 'concurrent'
require 'yaml'

module Peribot
  class Bot
    # This module provides the implementation of Peribot's configuration
    # facilities. When the configuration for an instance is requested, it is
    # generated on the fly from YAML files in the configuration directory.
    module Configuration
      # Retrieve a read-only object containing information from the
      # configuration directory.
      def config
        @config_builder.value || (fail @config_builder.reason)
      rescue NoMethodError
        raise 'No config directory defined'
      end

      private

      # Set the configuration directory from which information is loaded and
      # ensure that the object is built the next time the configuration is
      # requested.
      #
      # @param dir [String] The directory to load from
      def setup_config_directory(dir)
        fail 'No config directory defined' unless dir

        @config_builder = Concurrent::Delay.new do
          build_config(dir).freeze
        end
      end

      # Build a configuration object by loading YAML configuration files from a
      # directory.
      #
      # @param dir [String] The directory to load from
      def build_config(dir)
        files = Dir[File.join(dir, '*.conf')]
        files.reduce({}) do |config, file|
          basename = File.basename file, '.*'
          config.merge(basename => YAML.load_file(file))
        end
      end
    end
  end
end
