require 'concurrent'

module Peribot
  # Service represents a powerful and potentially complex message processing
  # task in Peribot. After being initialized with a {Peribot::Bot}, it will
  # receive a message and execute a set of handler methods based on its
  # content.
  #
  # Handler methods provide a nice, synchronous interface on top of Peribot's
  # totally async message processing flow. Additionally, they allow you to
  # focus on your service logic rather than filtering messages to determine
  # what actions you need to perform. Handlers are only executed when
  # necessary, and can return nil, a string, a fully-formatted Peribot message
  # hash, or an array consisting of any combination of these. They may also
  # raise an exception, which will be logged.
  #
  # While this class is mostly designed for complex services, it may also be
  # used for complex preprocessing, postprocessing, or sending logic. To do
  # this, you will wish to override the class-level register_into method to
  # insert your service into the appropriate message processing stage.
  #
  # There are three types of handlers provided: message handlers, command
  # handlers, and listen handlers. See the documentation for {.on_message},
  # {.on_command}, and {.on_listen} for more about each handler type.
  #
  # Note that within an instance of this class, the Peribot instance used to
  # initialize it will be available through the {#bot} accessor method.
  #
  # @example A message handler
  #   def my_handler(message:)
  #     do_stuff_with message
  #   end
  #
  #   # Register by passing the method name
  #   on_message :my_handler
  #
  # @example A command handler
  #   def my_command_handler(command:, arguments:, message:)
  #     do_stuff_for command, arguments
  #   end
  #
  #   # Register by passing the command and method name
  #   on_command :dostuff, :my_command_handler
  #
  # @example A listen handler
  #   def my_listen_handler(match:, message:)
  #     someone_mentioned match_data[1]
  #   end
  #
  #   # Register by passing the regex and method name
  #   # (may also be called as on_listen)
  #   on_hear /a (.*) handler/i, :my_listen_handler
  class Service
    include ErrorHelpers

    class << self
      # Run this service by initializing it and executing all handlers.
      def call(bot, message, &acceptor)
        this = new bot, acceptor
        this.accept message
      end

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

      # Register a method that will be called with a message object (via the
      # message keyword) every time a message is received.
      #
      # @param handler [Symbol] The name of the method to be called
      def on_message(handler)
        message_handlers << handler unless message_handlers.include? handler
      end

      # Register a method that will be called with a command, arguments, and
      # message (via those respective keywords) every time a message's text
      # begins with a particular command. A command is a hash (#) symbol
      # followed by a word, while arguments make up all text appearing after
      # the command. For example, in a weather service, the command "#weather
      # Seattle, WA" would have "weather" as the command and "Seattle, WA" as
      # the argument.
      #
      # @param command [Symbol] The command to look for
      # @param handler [Symbol] The name of the method to be called
      def on_command(command, handler)
        command_handlers[command.to_s] = handler
      end

      # Register a method that will be called with match data and a message
      # object (via the match and message keywords) every time a message's text
      # matches a particular regex. Note that if you desire a case-insensitive
      # match, you must include this option in your regex.
      #
      # @param regex [Regexp] The regex to use when matching messages
      # @param handler [Symbol] The name of the method to be called
      def on_hear(regex, handler)
        listen_handlers[regex] = handler
      end
      alias on_listen on_hear

      # Register this service into a {Peribot::Bot}. This allows for
      # {Peribot::Bot#use} to be used on any {Peribot::Service}.
      #
      # @param bot [Peribot::Bot] A Peribot instance
      def register_into(bot)
        bot.service.register self
      end
    end

    # Initialize a new service instance with a Peribot instance and acceptor.
    #
    # Note that in a future version of Peribot, services will no longer be
    # initialized with an acceptor. They will only be initialized with a bot,
    # and the acceptor will be given to the {#accept} method. The current
    # initialization strategy is maintained for backwards compatibility with
    # services that depend on the arity of this constructor. It is suggested
    # that extensions of this class that implement constructors use `def
    # initialize(*)` to ignore all arguments given to them, and call `super` as
    # their first action. Services can use {#bot} to obtain the bot instance.
    #
    # @param bot [Peribot] A Peribot object
    # @param acceptor [Proc] A Peribot acceptor that will receive messages
    def initialize(bot, acceptor)
      @bot = bot
      @acceptor = acceptor
    end

    # Begin processing a new message. This will cause each appropriate handler
    # method to be called. Any resulting messages will be sent to the acceptor
    # after all processing by the service is completed.
    #
    # @param message [Hash] The message to process
    # @return [Concurrent::Promise] A promise that can be waited on if necessary
    def accept(message)
      unless %i[text service group].all? { |k| message[k] }
        raise 'invalid message (must have text, service, and group)'
      end

      _invoke_all_handlers_async(message).then do |replies|
        Util.process_replies replies, message, &acceptor
      end
    end

    private

    attr_accessor :bot, :acceptor

    # (private)
    #
    # Run all handlers of all types in this service class, within the context
    # of a Concurrent::Promise. Replies will be grouped by handler type.
    def _invoke_all_handlers_async(message)
      Concurrent::Promise.execute do
        %i[message command listen].map do |type|
          __send__("_invoke_#{type}_handlers", message)
        end
      end
    end

    # (private)
    #
    # Run all message handlers in this service class.
    def _invoke_message_handlers(message)
      self.class.message_handlers.map do |handler|
        _safe_invoke handler, message: message
      end
    end

    # (private)
    #
    # Run all command handlers in this service class.
    def _invoke_command_handlers(message)
      self.class.command_handlers.map do |cmd, handler|
        text = message.fetch :text

        safe_cmd = Regexp.quote(cmd)
        next unless text =~ /\A##{safe_cmd}(?: |\z)/

        args = text.split.drop(1).join(' ')
        args = nil if args.empty?

        _safe_invoke handler, command: cmd, arguments: args, message: message
      end
    end

    # (private)
    #
    # Run all listen handlers in this service class.
    #
    # As different regexes can correspond to the same handler, we ensure that a
    # given handler is only called once for a particular message no matter how
    # many matches there are. We also ensure that regexes registered first take
    # priority when determining which match data is included.
    def _invoke_listen_handlers(message)
      text = message.fetch :text

      handlers = self.class.listen_handlers.map do |regex, handler|
        next unless text =~ regex
        [handler, regex.match(text)]
      end

      handlers.compact.uniq(&:first).map do |handler, match|
        _safe_invoke handler, match: match, message: message
      end
    end

    # (private)
    #
    # Invoke a handler function, and just log an exception if it fails (since
    # we want other handlers to continue running). In retrospect I'm not
    # convinced this is ideal behavior.
    def _safe_invoke(handler, **args)
      __send__(handler, **args)
    rescue StandardError => error
      log_failure error: error, message: args.fetch(:message),
                  logger: bot.public_method(:log)
      nil
    end
  end
end
