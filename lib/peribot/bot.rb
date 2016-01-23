require 'peribot/bot/configuration'
require 'peribot/bot/stores'

module Peribot
  # A class representing a Peribot instance, which registers services and
  # middleware tasks and provides facilities for configuration, persistent
  # storage, etc. This is the single most important part of a Peribot instance,
  # as it is what connects all other components together.
  class Bot
    include Peribot::Bot::Configuration
    include Peribot::Bot::Stores

    # Create a new Peribot instance and set up its basic configuration options.
    #
    # @param options [Hash] Options for this bot instance
    # @option options [String] :config_directory Directory with config files
    # @option options [String] :store_directory Directory for persistent stores
    def initialize(options = {})
      # See bot/configuration.rb and bot/stores.rb
      setup_config_directory options[:config_directory]
      setup_store_directory options[:store_directory]

      setup_middleware_chains

      @services = []
    end
    attr_reader :preprocessor, :postprocessor, :sender, :services

    # Send a message to this bot instance and process it through all middleware
    # chains and services. This method is really just a convenient way to send
    # a message to the preprocessor, but it is recommended rather than invoking
    # the preprocessor's #accept method directly.
    #
    # @param message [Hash] The message to process
    def accept(message)
      @preprocessor.accept message
    end

    # Register a service with this Peribot instance. It will be instantiated
    # and used to process each message that this bot receives. Services will
    # only be registered once regardless of how many times this method is
    # called with one.
    #
    # @param service [Class] A service that should receive messages
    def register(service)
      @services << service unless @services.include? service
    end

    # A simple logging function for use by Peribot components. Outputs the
    # given message to stderr with a "[Peribot]" prefix.
    #
    # @param message Text or other item to output to stderr
    def log(message)
      $stderr.puts "[Peribot] #{message}"
    end

    private

    # (private)
    #
    # Set up preprocessing, postprocessing, and sending chains for this bot
    # instance.
    def setup_middleware_chains
      @preprocessor = Peribot::ProcessorChain.new(self) do |message|
        dispatch message.freeze
      end

      @postprocessor = Peribot::ProcessorChain.new(self) do |message|
        @sender.accept message
      end

      @sender = Peribot::ProcessorChain.new(self)
    end

    # (private)
    #
    # Dispatch a message to all services in this bot instance.
    #
    # @param message [Hash] The message to send to services
    # @return [Array<Concurrent::IVar>] An array containing an IVar per service
    def dispatch(message)
      @services.map do |service|
        instance = service.new self, @postprocessor
        instance.accept message
      end
    end
  end
end
