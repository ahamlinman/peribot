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
    # An exception class that middleware tasks can use to stop message
    # processing without logging an error. It would be reasonable to argue that
    # an exception should not be used for this purpose, as it is not
    # representative of a failed state. However, I believe it is the simplest
    # solution for this purpose given the nature of the promise chains that
    # middleware chains are built on. This helps ensure that tasks are not
    # needlessly run and allows them to assume they will receive proper
    # messages, rather than a value like nil.
    #
    # It is suggested that this be used with caution and only for things that
    # administrators truly do not need to see in logs, such as the sender chain
    # being stopped after a message has been sent. Sender chains are the most
    # obvious (and intended) use case, though others might be appropriate as
    # well.
    class Stop < RuntimeError; end

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
        next if e.instance_of? Stop

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
