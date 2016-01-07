module Peribot
  module Middleware
    # Superclass representing a middleware task. Middleware tasks receive
    # messages (via the process instance method), change them as appropriate,
    # and pass them on to other middleware tasks or other parts of the Peribot
    # message chain.
    class Task
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
    end
  end
end
