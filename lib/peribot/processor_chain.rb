require 'concurrent'

module Peribot
  # This class is used to create processor chains. A chain consists of a number
  # of "processors" (tasks) followed by an end action. A message is sent into
  # the chain using the {#accept} method, where each processor handles it
  # before it is passed to the end action. Each individual message is only
  # processed by one task at a time, but all processing occurs asynchronously
  # on background threads. That is, if a particular task is delayed in
  # processing a message, that particular message may be delayed. However, the
  # processing of other messages will not be affected.
  #
  # This class is designed and intended for internal use within Peribot. It is
  # not considered public, and the API is not guaranteed to be stable.
  #
  # Peribot uses processor chains for preprocessing, postprocessing, and
  # sending messages. New chains are created by creating new instances of this
  # class. End actions are provided via a block passed to {#initialize}.
  class ProcessorChain
    # Create a new processor chain.
    #
    # @param bot [Peribot] A Peribot instance (for config, storage, etc.)
    # @yield [message] A message, processed by all tasks in the chain
    def initialize(bot, &end_action)
      @bot = bot
      @tasks = []
      @end_action = end_action if block_given?
    end
    attr_reader :tasks

    # Register a task with this processor chain. The given task will be
    # instantiated and used to process the message. Tasks will only be
    # registered once regardless of how many times this method is called with
    # one.
    #
    # @param task [Class] A class with a #process method taking a message
    def register(task)
      @tasks << task unless @tasks.include? task
    end

    # Begin processing a message using the tasks defined for this processor
    # chain.
    #
    # @param message [Hash] The message to process
    # @return [Concurrent::Promise] The pending promise chain
    def accept(message)
      promise_chain(message).execute
    end

    private

    # (private)
    #
    # Construct a promise chain for the given message. This is essentially a
    # task that gets run asynchronously on a thread pool, which will process
    # the message using the processors defined for this chain.
    #
    # @param message [Hash] The message to process
    # @return [Concurrent::Promise] The full promise chain for the message
    def promise_chain(message)
      promise = Concurrent::Promise.fulfill message
      promise = chain_tasks promise
      promise = promise.then(&@end_action) if @end_action

      promise.rescue do |e|
        next if e.instance_of? Peribot::Middleware::Stop

        @bot.log "Error in processing chain:\n"\
          "  => message = #{message.inspect}\n"\
        "  => exception = #{e.inspect}"
      end
    end

    # (private)
    #
    # Chain the tasks for this processor chain onto the given promise.
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