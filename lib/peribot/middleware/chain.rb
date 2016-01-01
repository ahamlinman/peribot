require 'concurrent'
require 'singleton'

module Peribot
  module Middleware
    # This class represents the prototype for a middleware chain. A chain
    # consists of a number of tasks followed by an end action. A message is
    # sent through the chain using the accept method, where it is
    # asynchronously processed by each task before being passed to the end
    # action.
    #
    # Peribot uses middleware chains for preprocessing, postprocessing, and
    # sending messages. New chains are created by extending this class and
    # overriding the end_action method if necessary.
    class Chain
      include Concurrent::Async
      include Singleton

      class << self
        def inherited(base)
          super

          # Define the chain of task classes
          base.instance_variable_set :@chain, []
          class << base; attr_reader :chain; end

          # Define a child Task class, which tasks intended for this chain will
          # subclass. That is, if MyChain subclasses this class, this line will
          # ensure that MyChain::Task is defined.
          base.const_set :Task, Peribot::Middleware::Task.build_class(base)
        end
      end

      # Called to perform the ending action for this middleware chain. That is,
      # this method is called with the final message once all tasks in the
      # chain have processed it. Subclasses should override this method.
      #
      # @param _message_ [Hash] The final, processed message
      def end_action(_message_)
      end

      # Begin processing a message using the tasks defined for this middleware
      # chain.
      #
      # @param message [Hash] The message to process
      # @return [Concurrent::Promise] The pending promise chain
      def accept(message)
        promise_chain(message).execute
      end

      # Construct a promise chain for the given message. This is essentially a
      # task that gets run on a thread pool in order to process the message
      # using the middleware tasks defined for this chain.
      #
      # @param message [Hash] The message to process
      # @return [Concurrent::Promise] The unscheduled promise chain
      def promise_chain(message)
        promise = Concurrent::Promise.fulfill message
        promise = chain_tasks promise
        promise = promise.then(&method(:end_action))

        promise.rescue do |e|
          Peribot.log "#{self.class}: Message processing stopped\n"\
                      "  => message = #{message.inspect}\n"\
                      "  => exception = #{e.inspect}"
        end
      end

      private

      # (private)
      #
      # Chain the tasks for this middleware chain onto the given promise.
      #
      # @param promise [Concurrent::Promise] The initial promise
      # @return [Concurrent::Promise] The promise with additional children
      def chain_tasks(promise)
        self.class.chain.inject(promise) do |current_chain, task|
          current_chain.then { |msg| task.new.process msg }
        end
      end
    end
  end
end
