require 'concurrent'

module Peribot
  # A base class for services in Peribot. Services provide most of Peribot's
  # serious functionality by processing messages received from groups and
  # creating replies to be sent in return. Messages are immutable (frozen)
  # hashes containing, at minimum, values for 'group_id' and 'text'.
  #
  # While any class that implements {#accept} properly can act as a Peribot
  # service, this class provides convenient functionality for writing services,
  # including class methods to register methods as message handlers and the
  # ability to respond to messages by simply returning a string.
  #
  # There are three types of handlers in this class: message handlers, command
  # handlers, and listen handlers. See the documentation for {on_message},
  # {on_command}, and {on_listen} for more about each handler type.
  #
  # @example A message handler
  #   def my_handler(message)
  #     do_stuff_with message
  #   end
  #
  #   # Register by passing the method name
  #   on_message :my_handler
  #
  # @example A command handler
  #   def my_command_handler(command, arguments, message)
  #     do_stuff_for command, arguments
  #   end
  #
  #   # Register by passing the command and method name
  #   on_command :dostuff, :my_command_handler
  #
  # @example A listen handler
  #   def my_listen_handler(match_data, message)
  #     someone_mentioned match_data[1]
  #   end
  #
  #   # Register by passing the regex and method name
  #   # (may also be called as on_listen)
  #   on_hear /a (.*) handler/i, :my_listen_handler
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
        message_handlers << handler unless message_handlers.include? handler
      end

      # Register a method that will be called with a command, arguments, and
      # message every time a message's text begins with a particular command. A
      # command is a hash (#) symbol followed by a word, while arguments make
      # up all text appearing after the command. For example, in a weather
      # service, the command "#weather Seattle, WA" would have "weather" as the
      # command and "Seattle, WA" as the argument.
      #
      # @param command [Symbol] The command to look for
      # @param handler [Symbol] The name of the method to be called
      def on_command(command, handler)
        command_handlers[command.to_s] = handler
      end

      # Register a method that will be called with match data and a message
      # object every time a message's text matches a particular regex. Note
      # that if you desire a case-insensitive match, you must include this
      # option in your regex.
      #
      # @param regex [Regexp] The regex to use when matching messages
      # @param handler [Symbol] The name of the method to be called
      def on_hear(regex, handler)
        listen_handlers[regex] = handler
      end
      alias on_listen on_hear
    end

    # Initialize a new service instance with a Peribot instance (that may be
    # used for configuration and persistent storage) and an acceptor (an
    # object that can receive :accept with completed messages to send).
    #
    # @param bot [Peribot] A Peribot object
    # @param acceptor A class implementing #accept that will receive replies
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
    # @return [Concurrent::IVar] An IVar that can be waited on if necessary
    def accept(message)
      unless message['text'] && message['group_id']
        fail 'invalid message (must have text and group_id)'
      end

      promise = Concurrent::Promise.fulfill []
      promise = chain_handlers promise, message
      promise.then { |msgs| end_action msgs, message.fetch('group_id') }
    end

    private

    attr_accessor :bot, :acceptor

    # (private)
    #
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

    # (private)
    #
    # Chain calls to message handlers onto a promise.
    #
    # @see chain_handlers
    def chain_message_handlers(promise, message)
      self.class.message_handlers.reduce(promise) do |prom, handler|
        prom.then(&handler_proc(handler, message))
      end
    end

    # (private)
    #
    # Chain calls to command handlers onto a promise
    #
    # @see chain_handlers
    def chain_command_handlers(promise, message)
      self.class.command_handlers.reduce(promise) do |prom, (cmd, handler)|
        text = message.fetch 'text'

        safe_cmd = Regexp.quote(cmd)
        next prom unless text =~ /\A##{safe_cmd}(?: |\z)/

        args = text.split[1..-1].join(' ')
        args = nil if args.empty?

        prom.then(&handler_proc(handler, cmd, args, message))
      end
    end

    # (private)
    #
    # Chain calls to listen handlers onto a promise
    #
    # @see chain_handlers
    def chain_listen_handlers(promise, message)
      listen_matches(message).reduce(promise) do |prom, (handler, match)|
        prom.then(&handler_proc(handler, match, message))
      end
    end

    # (private)
    #
    # Obtain a deduplicated list of listen handlers and associated regex match
    # data for a given message. As different regexes can correspond to the same
    # handler, this ensures that a given handler is only called once for a
    # particular message no matter how many matches there are. It also ensures
    # that regexes registered first take priority when determining which match
    # data is included.
    #
    # @param message [Hash] The message being processed
    # @return [Hash] A map from handler functions to match data
    def listen_matches(message)
      text = message.fetch 'text'

      handlers = self.class.listen_handlers.map do |regex, handler|
        next unless text =~ regex
        [handler, regex.match(text)]
      end
      handlers.compact.uniq(&:first)
    end

    # (private)
    #
    # Get a proc that can be chained onto a promise to call a handler method.
    #
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
          msgs << __send__(*args, message)
        rescue => error
          failure_action error, message
          msgs
        end
      end
    end

    # (private)
    #
    # Send any messages created by handlers to the acceptor.
    #
    # @param replies [Array] Replies from handlers in this service
    # @param gid [String] The default group to reply to (if not in a message)
    def end_action(replies, gid)
      msgs = replies.flatten.reject(&:nil?)
      msgs = convert_strings_to_replies msgs, gid
      msgs.each { |msg| acceptor.accept msg }
    end

    # (private)
    #
    # Normalize an array containing mixed strings and messages so that it
    # only contains message hashes.
    #
    # @param replies [Array] An array of replies to a message
    # @param gid [String] A group to reply to when a message does not have one
    # @return [Array<Hash>] A normalized array of replies
    def convert_strings_to_replies(replies, gid)
      replies.map do |reply|
        next reply unless reply.instance_of? String
        { 'group_id' => gid, 'text' => reply }
      end
    end

    # (private)
    #
    # Handle errors in message processing by printing the error to stderr.
    #
    # @param error [Exception] The error that was raised
    # @param message [Hash] The message being processed
    def failure_action(error, message)
      bot.log "#{self.class}: Error while processing message\n"\
              "  => message = #{message.inspect}\n"\
              "  => exception = #{error.inspect}\n"\
              "  => backtrace:\n#{format_backtrace error.backtrace}"
    end

    # (private)
    #
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
