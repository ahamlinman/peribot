require 'concurrent'
require 'yaml'

module Peribot
  class Bot
    # This module provides functionality for configuring and working with the
    # configuration of Peribot::Bot instances.
    module Configuration
      # Obtain the saved configuration (loading it if necessary).
      def config
        @config || configure(load_config.freeze)
      end

      # Set the configuration from a given Hash or through a block (for
      # DSL-style configuration).
      def configure(config = nil, &block)
        config ||= Peribot::Util::BlockHashBuilder.build(&block)
        @config = config.dup.freeze
      end

      private

      def load_config
        @config_file ||= ENV['PERIBOT_CONFIG'] || File.expand_path('config.yml')
        YAML.load_file(@config_file).freeze
      rescue Errno::ENOENT
        raise 'Could not find configuration'
      end
    end
  end
end
