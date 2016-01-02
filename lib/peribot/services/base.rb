module Peribot
  module Services
    # Base class for all Peribot services. This provides the on_message,
    # on_command, and on_hear class methods, and ensures that all services are
    # properly registered so that they can receive messages.
    class Base
      class << self
        # Ensure that handler lists get set in subclasses, and allow them to be
        # accessible.
        def inherited(base)
          Peribot::Services.list << base

          base.instance_variable_set :@message_handlers, []
          base.instance_variable_set :@command_handlers, {}
          base.instance_variable_set :@listen_handlers, {}

          class << base
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
    end
  end
end
