require 'concurrent'

module Peribot
  # Processor represents a highly generic message processing task in Peribot.
  # After being initialized with a {Peribot::Bot}, it will receive a message
  # via its {#process} method, perform actions and transformations as
  # appropriate, and return messages for further processing.
  #
  # This class helps provide a nice, synchronous interface on top of Peribot's
  # totally async message processing flow. It is mostly designed for use by
  # preprocessing, postprocessing, and sending tasks. However, services that
  # would normally contain only a single message handler could also be
  # implemented using Processor.
  #
  # Classes that extend this service should implement their own
  # {.register_into} method that inserts it into the appropriate processing
  # stage of a Peribot instance. For example, when writing a preprocessor:
  #
  #   def self.register_into(bot)
  #     bot.preprocessor.register self
  #   end
  #
  # This allows use of the {Peribot::Bot#use} method with your class.
  #
  # Note that within an instance of this class, the Peribot instance used to
  # initialize it will be availble through the {#bot} accessor method.
  class Processor
    class << self
      include ErrorHelpers

      # Run this processor by initializing it, executing the {#process} method,
      # and normalizing the response.
      #
      # @param bot [Peribot::Bot] A Peribot instance
      # @param message [Hash] A Peribot-formatted message
      # @yield One or more messages for further processing
      def call(bot, message, &acceptor)
        Concurrent::Future.execute do
          this = new bot

          begin
            result = this.process message
          rescue StandardError => e
            log_failure error: e, message: message,
                        logger: bot.public_method(:log)
          end

          Util.process_replies [result], message, &acceptor
        end
      end

      # Throw an error stating that this Processor class does not give a proper
      # .register_into implementation. For more information about properly
      # overriding this method, see the class documentation.
      def register_into(_)
        raise NotImplementedError, "#{self} does not support Peribot::Bot#use"
      end
    end

    # Create a new instance of this processor.
    #
    # @param bot [Peribot] A Peribot instance
    def initialize(bot)
      @bot = bot
    end

    # Process a message. This method may perform one of the following actions:
    #
    # * Return the message unchanged
    # * Return a modified message
    # * Return nil to discard the message and prevent further processing
    # * Return an array of messages to process all of them further
    # * Raise an error to log it and prevent further processing
    #
    # @param _message_ [Hash] The message to be processed
    # @return Messages that should be processed further
    def process(_message_)
      raise "process method not implemented in #{self.class}"
    end

    private

    attr_reader :bot
  end
end
