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
    include ErrorHelpers

    # An exception class that is used to stop message processing without
    # logging an error. It would be reasonable to argue that an exception
    # should not be used for this purpose, as it is not representative of a
    # failed state. However, I believe it is the simplest solution for this
    # purpose given the nature of the promise chains that middleware chains are
    # built on. This helps ensure that tasks are not needlessly run and allows
    # them to assume they will receive proper messages, rather than a value
    # like nil.
    #
    # It is not expected that processors will raise this exception directly.
    # Rather, they can return nil and it will be raised for them in order to
    # stop the processor chain and avoid needless processing, as described
    # above.
    Stop = Class.new RuntimeError

    attr_reader :tasks

    # Create a new processor chain.
    #
    # @param bot [Peribot] A Peribot instance (for config, storage, etc.)
    # @yield [message] A message, processed by all tasks in the chain
    def initialize(bot, &end_action)
      @bot = bot
      @end_action = end_action
      @tasks = []
    end

    # Register a task with this processor chain. The given task will be
    # instantiated and used to process the message. Tasks will only be
    # registered once regardless of how many times this method is called with
    # one.
    #
    # @param task [Class] A class with a #process method taking a message
    def register(task)
      tasks << task unless tasks.include? task
    end

    # Begin processing a message using the tasks defined for this processor
    # chain.
    #
    # @param message [Hash] The message to process
    # @return [Concurrent::IVar] An IVar that can be waited on if necessary
    def accept(message)
      # Note that #execute does not actually need to be called on the promise
      # returned by #promise_chain. Because the promise begins in the fulfilled
      # state, any children immediately get posted to the executor. This is not
      # made clear in the concurrent-ruby documentation, though I do not expect
      # it to change given how promises are intended to work in general.
      promise_chain(message)
    end

    private

    attr_reader :bot, :end_action

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
      promise = promise.then(&end_action) if end_action

      promise.rescue do |e|
        # (29 January 2016) THIS MUST BE 'next' AND NOT 'break'! Using 'break'
        # leads to an infinite hang on JRuby for reasons that I honestly don't
        # fully understand (I'm actually a bit surprised that it doesn't cause
        # a similar issue on MRI). At least for now, I have written a test to
        # make sure that this does not get changed.
        next if e.instance_of? Stop

        log_failure error: e, message: message
      end
    end

    # (private)
    #
    # Chain the tasks for this processor chain onto the given promise.
    #
    # @param promise [Concurrent::Promise] The initial promise
    # @return [Concurrent::Promise] The promise with additional children
    def chain_tasks(promise)
      tasks.reduce(promise) do |current_chain, task|
        current_chain.then do |msg|
          task.new(bot).process(msg) || raise(Stop)
        end
      end
    end
  end
end
