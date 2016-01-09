require 'concurrent'

module Peribot
  # Base class for all Peribot services. This provides the on_message,
  # on_command, and on_hear class methods, and ensures that all services are
  # properly registered so that they can receive messages.
  class Service
    class << self
      # Ensure that handler lists get set in subclasses, and allow them to be
      # accessible.
      def inherited(subclass)
        subclass.instance_variable_set :@message_handlers, []
        subclass.instance_variable_set :@command_handlers, {}
        subclass.instance_variable_set :@listen_handlers, {}

        class << subclass
          attr_reader :message_handlers, :command_handlers, :listen_handlers
        end
      end

      # Register a method that will be called with a message object every
      # time a message is received.
      #
      # @param handler [Symbol] The name of the method to be called
      def on_message(handler)
        @message_handlers << handler
      end

      # Register a method that will be called with a command, arguments, and
      # message every time a message's text begins with a particular command
      # (e.g. #command).
      #
      # @param command [Symbol] The command to look for
      # @param handler [Symbol] The name of the method to be called
      def on_command(command, handler)
        @command_handlers[command.to_s] = handler
      end

      # Register a method that will be called with match data and a message
      # object every time a message's text matches a particular regex.
      #
      # @param regex [Regexp] The regex to use when matching messages
      # @param handler [Symbol] The name of the method to be called
      def on_hear(regex, handler)
        @listen_handlers[regex] = handler
      end
    end

    # Initialize a new service instance with a Peribot instance (that may be
    # used for configuration and persistent storage) and an acceptor (an
    # object that can receive :accept with completed messages to send).
    #
    # @param bot [Peribot] A Peribot object
    # @param acceptor [Peribot::Middleware::Chain] Receives reply messages
    def initialize(bot, acceptor)
      @bot = bot
      @acceptor = acceptor
    end

    # Begin processing a new message. This will cause each appropriate
    # handler method to be called. Any messages that handler methods wish to
    # send will be sent to the postprocessing chain after processing by the
    # service is completed.
    #
    # @param message [Hash] The message to process
    # @return [Concurrent::Promise] A promise chain for this message
    def accept(message)
      promise = Concurrent::Promise.fulfill []
      promise = chain_handlers promise, message
      promise = promise.then { |msgs| end_action msgs, message }

      promise.execute
    end

    private

    # Chain calls to appropriate handler methods onto the given promise.
    #
    # @param promise [Concurrent::Promise] The initial promise
    # @param message [Hash] The message being processed
    # @return [Concurrent::Promise] The promise with handlers
    def chain_handlers(promise, message)
      promise = chain_message_handlers promise, message
      promise = chain_command_handlers promise, message
      chain_listen_handlers promise, message
    end

    # Chain calls to message handlers onto a promise.
    #
    # @see chain_handlers
    def chain_message_handlers(promise, message)
      self.class.message_handlers.reduce(promise) do |prom, handler|
        prom.then(&handler_proc(handler, message))
      end
    end

    # Chain calls to command handlers onto a promise
    #
    # @see chain_handlers
    def chain_command_handlers(promise, message)
      self.class.command_handlers.reduce(promise) do |prom, (cmd, handler)|
        next prom unless message['text'].match(/\A##{cmd}/)

        args = message['text'].split[1..-1].join(' ')
        args = nil if args.length == 0

        prom.then(&handler_proc(handler, cmd, args, message))
      end
    end

    # Chain calls to listen handlers onto a promise
    #
    # @see chain_handlers
    def chain_listen_handlers(promise, message)
      self.class.listen_handlers.reduce(promise) do |prom, (regex, handler)|
        next prom unless message['text'] =~ regex

        match = regex.match message['text']
        prom.then(&handler_proc(handler, match, message))
      end
    end

    # Get a proc that can be chained onto a promise to call a handler method.
    #
    # @param handler [Symbol] The handler method to call
    # @param message [Hash] The message being processed
    #
    # @overload handler_proc(handler, message)
    #   Obtain a proc to call a message handler
    #
    # @overload handler_proc(handler, cmd, args, message)
    #   Obtain a proc to call a command handler
    #   @param cmd [String] The command that was given
    #   @param args [String] Arguments to the command
    #
    # @overload handler_proc(handler, match, message)
    #   Obtain a proc to call a listen handler
    #   @param match [MatchData] Regex match information for the message
    #
    # @return [Proc] A proc that will call the handler
    def handler_proc(*args, message)
      proc do |msgs|
        begin
          msgs << send(*args, message)
        rescue => error
          failure_action error, message
          msgs
        end
      end
    end

    # Send any messages created by handlers to the postprocessing chain.
    #
    # @param message [Hash] The message being processed
    def end_action(replies, original)
      msgs = replies.flatten.reject(&:nil?)
      msgs = convert_strings_to_replies msgs, original
      msgs.each { |msg| @acceptor.accept msg }
    end

    # Normalize an array containing mixed strings and messages so that it
    # only contains message hashes.
    #
    # @param replies [Array] An array of replies to a message
    # @param original [Hash] The original message
    # @return [Array<Hash>] A normalized array of replies
    def convert_strings_to_replies(replies, original)
      replies.map do |reply|
        next reply unless reply.is_a? String
        { 'group_id' => original['group_id'], 'text' => reply }
      end
    end

    # Handle errors in message processing by printing the error to stderr.
    #
    # @param error [Exception] The error that was raised
    # @param message [Hash] The message being processed
    def failure_action(error, message)
      @bot.log "#{self.class}: Error while processing message\n"\
        "  => message = #{message.inspect}\n"\
      "  => exception = #{error.inspect}\n"\
      "  => backtrace:\n#{format_backtrace error.backtrace}"
    end

    # Format an exception backtrace for printing to the log.
    #
    # @param backtrace [Array<String>] Lines of the backtrace
    # @return [String] An indented backtrace with newlines
    def format_backtrace(backtrace)
      indent = 5
      backtrace.map { |line| line.prepend(' ' * indent) }.join("\n")
    end
  end
end
