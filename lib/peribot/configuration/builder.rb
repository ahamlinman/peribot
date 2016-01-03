module Peribot
  class Configuration
    # A builder to create Peribot::Configuration objects. This is intended to
    # be evaluated with Docile through the Peribot.configure method.
    class Builder
      def initialize
        @config = Peribot::Configuration.new
      end

      # Retrieve a built, frozen Peribot::Configuration object.
      #
      # @return [Peribot::Configuration]
      def build
        @config.freeze
      end

      # Set the directory from which configuration files should be read.
      def conf_directory(dir)
        @config.conf_directory = dir
        self
      end

      # Set the directory where persistent storage files should be saved.
      def store_directory(dir)
        @config.store_directory = dir
        self
      end
    end
  end
end
