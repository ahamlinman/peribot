module Peribot
  # Superclass representing a processor task. Processor tasks receive messages
  # (via the {#process} method), change them as appropriate, and pass them on
  # to other tasks or other parts of the Peribot message chain.
  #
  # It is suggested that tasks extend this class for convenience, though any
  # class that includes a {#process} method taking a message should be
  # acceptable. Keep in mind that all instances are initialized with a
  # {Peribot::Bot} that provides various services for tasks and other
  # components.
  #
  # It is further suggested that any subclasses implement a class-level
  # {.register_into} method that inserts the class into the appropriate
  # processor chain within a {Peribot::Bot}. For example, if you are writing a
  # preprocessor, your implementation should be as follows:
  #
  #   def self.register_into(bot)
  #     bot.preprocessor.register self
  #   end
  class Processor
    class << self
      include ErrorHelpers

      # Required for ErrorHelpers, unfortunately.
      def bot; end

      # Allow Peribot::Processor to support the Peribot 0.9.x processor
      # specification. This is an updated vision of "processors" in Peribot
      # that allows for vastly improved flexibility.
      def call(bot, message)
        this = new bot

        begin
          result = this.process message
        rescue => e
          log_failure error: e, message: message, logger: bot.method(:log)
        end

        return unless result
        yield result
      end

      # Throw an error stating that this Processor class does not give a proper
      # .register_into implementation. It is recommended that subclasses of
      # Peribot::Processor define a class-level .register_into method so that
      # they can be used as an argument to Peribot::Bot#use. The implementation
      # should register the Processor into the appropriate processor chain
      # (preprocessing, postprocessing, or sending).
      def register_into(_)
        raise NotImplementedError, "#{self} does not support Peribot::Bot#use"
      end
    end

    # Create a new instance of this middleware task.
    #
    # @param bot [Peribot] A Peribot instance
    def initialize(bot)
      @bot = bot
    end

    # Process a message within this task. This method may perform one of the
    # following actions:
    # * Return the message unchanged
    # * Return a modified message
    # * Return nil to discard the message and prevent further processing
    # * Raise an error to log it and prevent further processing
    #
    # @param _message_ [Hash] The message to be processed
    # @return [Hash] A message, potentially changed by this task
    def process(_message_)
      raise "process method not implemented in #{self.class}"
    end

    private

    attr_reader :bot
  end
end
