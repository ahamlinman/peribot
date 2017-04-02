require 'concurrent'
require 'yaml'

module Peribot
  class Bot
    # Bot::Configuration provides functionality for configuring and working
    # with the configuration of {Peribot::Bot} instances.
    module Configuration
      # Obtain the saved configuration (loading it if necessary).
      def config
        @config || configure(load_config)
      end

      # Set the configuration from a given Hash or through a block (for
      # DSL-style configuration).
      def configure(config = nil, &block)
        config ||= Util::BlockHashBuilder.build(&block)
        @config = config.dup.freeze
      end

      def config_file
        @config_file ||= ENV['PERIBOT_CONFIG'] || File.expand_path('config.yml')
      end

      private

      def load_config
        YAML.load_file(config_file)
      rescue Errno::ENOENT
        raise 'Could not find configuration'
      end
    end
  end
end
