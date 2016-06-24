require 'concurrent'
require 'yaml'

module Peribot
  class Bot
    # This module provides functionality for configuring and working with the
    # configuration of Peribot::Bot instances.
    module Configuration
      def config
        @config ||= load_config.freeze
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
