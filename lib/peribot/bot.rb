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

    # The set of stages used by a {Bot} to process messages. Each stage will
    # have a registry within the bot instance, which provides
    # {ProcessorRegistry#register} and {ProcessorRegistry#list} methods for
    # registering processors or seeing which processors have been previously
    # registered to that stage.
    #
    # When a message is processed using the given stage, an instance of the
    # given processor class will be constructed using the processors defined in
    # the corresponding registry, and used to process the message. Resulting
    # messages will be processed by the next stage in the list, until all
    # stages have been executed.
    STAGES = {
      filter: ProcessorChain,
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
        map[key] = Util::KeyValueAtom.new
      end

      setup_registries
    end
    attr_reader :caches

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
    # It is expected that this method will be used only at startup, before any
    # message processing begins. Peribot's registration functionality is not
    # explicitly thread-safe, and the behavior of pipelines while processors
    # are actively being registered is not defined.
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

    # Process a message using all processors registered with this bot instance.
    # Messages can optionally be sent to an arbitrary stage to bypass portions
    # of the pipeline. Otherwise, they are sent to the first stage.
    #
    # @param message [Hash] The message to process
    # @param stage [Symbol] The stage to send the message to
    def accept(message, stage: STAGES.keys.first)
      raise KeyError, "invalid stage: #{stage}" unless STAGES.include? stage

      stages = STAGES.drop_while { |s, _| s != stage }
                     .map { |s, cls| cls.new @registries.fetch(s).list }

      ProcessorChain.new(stages).call(self, message) { |*| }
    end

    private

    # (private)
    #
    # Set up the registries used to construct pipelines.
    def setup_registries
      @registries = {}

      STAGES.each_key do |stage|
        @registries[stage] = ProcessorRegistry.new
        define_singleton_method(stage) { @registries.fetch stage }
      end
    end
  end
end
