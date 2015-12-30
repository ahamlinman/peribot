module Peribot
  module Middleware
    # Superclass representing a middleware task. Middleware tasks receive
    # messages (via the process instance method), change them as appropriate,
    # and pass them on to other middleware tasks or other parts of the Peribot
    # message chain.
    class Task
      # Define and return a new subclass of Peribot::Middleware::Task that will
      # add its subclasses to chain_class.chain. In other words, this is what
      # ensures that all task classes get added to the proper chains.
      #
      # @param chain_class [Class] The middleware chain class
      def self.build_class(chain_class)
        Class.new(self) do |cls|
          cls.define_singleton_method :inherited do |base|
            chain_class.chain << base
          end
        end
      end

      # Process a message within this middleware task. This method may perform
      # one of the following actions:
      # * Return the message unchanged
      # * Return a modified message
      # * Raise StopIteration to prevent further processing
      #
      # @param _message_ [Hash] The message to be processed
      # @return [Hash] A message, potentially changed by this task
      def process(_message_)
        fail "process method not implemented in #{self.class}"
      end
    end
  end
end
