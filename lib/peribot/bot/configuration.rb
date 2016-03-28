require 'concurrent'
require 'yaml'

module Peribot
  class Bot
    # This module provides the implementation of Peribot's configuration
    # facilities. The configuration hash for an instance is lazily loaded from
    # YAML files with a .conf extension in a specified directory. Filenames
    # make up hash keys, and the value for each key represents the content of
    # the file. The configuration hash is read-only (frozen) to help simplify
    # thread-safe access and usage given Peribot's concurrent nature.
    module Configuration
      # Retrieve a read-only object containing information from the
      # configuration directory.
      #
      # @return [Hash] The full configuration for the bot instance
      def config
        config_builder.value || (raise config_builder.reason)
      rescue NoMethodError
        raise 'No config directory defined'
      end

      private

      attr_reader :config_builder

      # (private)
      #
      # Set the configuration directory from which information is loaded and
      # ensure that the object is built the next time the configuration is
      # requested.
      #
      # @param dir [String] The directory to load from
      def setup_config_directory(dir)
        raise 'No config directory defined' unless dir

        @config_builder = Concurrent::Delay.new do
          build_config(dir).freeze
        end
      end

      # (private)
      #
      # Build a configuration object by loading YAML configuration files from a
      # directory.
      #
      # @param dir [String] The directory to load from
      # @return [Hash] The full instance configuration
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
