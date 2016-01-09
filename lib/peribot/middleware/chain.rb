require 'concurrent'
require 'singleton'

module Peribot
  module Middleware
    # This class is used to create middleware chains. A chain consists of a
    # number of tasks followed by an end action. A message is sent through the
    # chain using the accept method, where it is asynchronously processed by
    # each task before being passed to the end action.
    #
    # Peribot uses middleware chains for preprocessing, postprocessing, and
    # sending messages. New chains are created by creating new instances of
    # this class. End actions are provided via a block passed to
    # Peribot::Middleware::Chain.new.
    class Chain
      # Create a new middleware chain. A block may be passed in order to define
      # the end action for this chain - that is, where messages are passed once
      # processing is completed.
      #
      # @param bot [Peribot] A Peribot instance (for config, storage, etc.)
      def initialize(bot, &end_action)
        @bot = bot
        @tasks = []
        @end_action = end_action if block_given?
      end
      attr_reader :tasks

      # Register a task with this middleware chain. The given task will be
      # instantiated and used to process the message.
      #
      # @param task [Class] A class with a #process method taking a message
      def register(task)
        @tasks << task
      end

      # Begin processing a message using the tasks defined for this middleware
      # chain.
      #
      # @param message [Hash] The message to process
      # @return [Concurrent::Promise] The pending promise chain
      def accept(message)
        promise_chain(message).execute
      end

      private

      # Construct a promise chain for the given message. This is essentially a
      # task that gets run on a thread pool in order to process the message
      # using the middleware tasks defined for this chain.
      #
      # @param message [Hash] The message to process
      # @return [Concurrent::Promise] The unscheduled promise chain
      def promise_chain(message)
        promise = Concurrent::Promise.fulfill message
        promise = chain_tasks promise
        promise = promise.then(&@end_action) if @end_action

        promise.rescue do |e|
          next if e.instance_of? Peribot::Middleware::Stop

          @bot.log "#{self.class}: Message processing stopped\n"\
                   "  => message = #{message.inspect}\n"\
                   "  => exception = #{e.inspect}"
        end
      end

      # (private)
      #
      # Chain the tasks for this middleware chain onto the given promise.
      #
      # @param promise [Concurrent::Promise] The initial promise
      # @return [Concurrent::Promise] The promise with additional children
      def chain_tasks(promise)
        @tasks.reduce(promise) do |current_chain, task|
          current_chain.then { |msg| task.new(@bot).process msg }
        end
      end
    end
  end
end
