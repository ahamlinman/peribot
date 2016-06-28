require 'peribot/bot/configuration'
require 'peribot/bot/stores'
require 'yaml'

module Peribot
  # A class representing a Peribot instance, which registers services and
  # middleware tasks and provides facilities for configuration, persistent
  # storage, etc. This is the single most important part of a Peribot instance,
  # as it is what connects all other components together.
  class Bot
    include Configuration
    include Stores

    # Create a new Peribot instance and set up its basic configuration options.
    # All bot instances require a configuration file (containing instance
    # configuration options) and a store file (to save information that should
    # be persisted across multiple runs). These options can be provided
    # directly as arguments. If not provided in this manner, Peribot will
    # attempt to use the PERIBOT_CONFIG and PERIBOT_STORE environment
    # variables.
    #
    # @param config_file [String] The location of a YAML configuration file
    # @param store_file [String] The location for the PStore file
    def initialize(config_file: nil, store_file: nil)
      # See bot/configuration.rb and bot/stores.rb
      @config_file = config_file
      @store_file = store_file

      @caches = Concurrent::Map.new do |map, key|
        map[key] = Peribot::Util::KeyValueAtom.new
      end

      @services = []

      setup_middleware_chains
    end
    attr_reader :preprocessor, :postprocessor, :sender, :services, :caches

    # Send a message to this bot instance and process it through all middleware
    # chains and services. This method is really just a convenient way to send
    # a message to the preprocessor, but it is recommended rather than invoking
    # the preprocessor's #accept method directly.
    #
    # @param message [Hash] The message to process
    def accept(message)
      preprocessor.accept message
    end

    # Register a service with this Peribot instance. It will be instantiated
    # and used to process each message that this bot receives. Services will
    # only be registered once regardless of how many times this method is
    # called with one.
    #
    # @param service [Class] A service that should receive messages
    def register(service)
      services << service unless services.include? service
    end

    # Have the bot make use of some given functionality. This general method is
    # intended to be the primary means for configuring the functionalities of a
    # {Peribot::Bot} instance.
    #
    # When called, this method will invoke the 'register_into' method of the
    # given item with the bot instance as an argument, along with any
    # additional arguments. The item can then register itself into the bot
    # instance in the most appropriate manner. For example, calling this method
    # with a single {Peribot::Service} will register that service with the bot.
    # Calling this method with Peribot::GroupMe, on the other hand, will
    # register a variety of senders and postprocessors that allow the bot to
    # communicate with GroupMe.
    #
    # @param item An item for this bot to use
    # @example Configure a simple Peribot instance
    #   @bot.use Peribot::GroupMe
    #   @bot.use MyCustomService
    def use(item, *args)
      item.register_into self, *args
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
      @preprocessor = ProcessorChain.new(self) do |message|
        dispatch message.freeze
      end

      @postprocessor = ProcessorChain.new(self) do |message|
        sender.accept message
      end

      @sender = ProcessorChain.new(self)
    end

    # (private)
    #
    # Dispatch a message to all services in this bot instance.
    #
    # @param message [Hash] The message to send to services
    # @return [Array<Concurrent::IVar>] An array containing an IVar per service
    def dispatch(message)
      services.map do |service|
        instance = service.new self, postprocessor
        instance.accept message
      end
    end
  end
end
