require 'peribot/bot/configuration'
require 'peribot/bot/stores'

module Peribot
  # Bot represents a Peribot instance, including lists of tasks used to
  # construct message processing pipelines as well as all shared/persistent
  # state and configuration for processors. Essentially, it is the glue that
  # holds any working Peribot instance together.
  class Bot
    include Configuration
    include Stores

    STAGES = {
      preprocessor: ProcessorChain,
      service: ProcessorGroup,
      postprocessor: ProcessorChain,
      sender: ProcessorGroup
    }.freeze

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

      setup_registries
    end
    attr_reader :caches

    # Register a service with this Peribot instance. It will be instantiated
    # and used to process each message that this bot receives. Services will
    # only be registered once regardless of how many times this method is
    # called with one.
    #
    # @deprecated Use Bot#service.register instead
    #
    # @param service [Class] A service that should receive messages
    def register(s)
      service.register s
    end

    # Obtain an array of the services registered with this bot.
    #
    # @deprecated Use Bot#service.list instead
    def services
      service.list
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

    # Output the given message to stderr with a "[Peribot]" prefix. This helps
    # provide a consistent logging format and method for processors.
    #
    # @param message Text or other item to output to stderr
    def log(message)
      $stderr.puts "[Peribot] #{message}"
    end

    # Process a message using this bot instance by sending it to the first
    # message processing stage (the preprocessor). Optionally, messages can be
    # sent to an arbitrary stage to bypass portions of the pipeline.
    #
    # @param message [Hash] The message to process
    # @param stage [Symbol] The stage to send the message to
    def accept(message, stage: STAGES.keys.first)
      STAGES[stage].new(@registries[stage].list).call(self, message) do |out|
        remaining = STAGES.keys.drop_while { |s| s != stage }.drop(1)
        accept(out, stage: remaining.first) unless remaining.empty?
      end
    end

    private

    # (private)
    #
    # Set up the registries used to construct pipelines.
    def setup_registries
      @registries = {}

      STAGES.keys.each do |stage|
        @registries[stage] = ProcessorRegistry.new
        define_singleton_method(stage) { @registries[stage] }
      end
    end
  end
end
