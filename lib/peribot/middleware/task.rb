module Peribot
  module Middleware
    # Superclass representing a middleware task. Middleware tasks receive
    # messages (via the process instance method), change them as appropriate,
    # and pass them on to other middleware tasks or other parts of the Peribot
    # message chain.
    class Task
      # Create a new instance of this middleware task.
      #
      # @param _bot_ [Peribot] A Peribot instance
      def initialize(_bot_)
      end

      # Process a message within this middleware task. This method may perform
      # one of the following actions:
      # * Return the message unchanged
      # * Return a modified message
      # * Raise an error to prevent further processing
      #
      # @param _message_ [Hash] The message to be processed
      # @return [Hash] A message, potentially changed by this task
      def process(_message_)
        fail "process method not implemented in #{self.class}"
      end

      # Stop further processing of this message in this pipeline. This prevents
      # any further tasks in the middleware chain, including the end action,
      # from running. However, it will not raise any error or give any other
      # indication that processing has stopped.
      #
      # Within the preprocessing and postprocessing chains, this is effectively
      # the same as discarding a message. Thus, this method may also be called
      # as discard_message.
      def stop_processing
        fail Peribot::Middleware::Stop
      end
      alias_method :discard_message, :stop_processing
    end
  end
end
