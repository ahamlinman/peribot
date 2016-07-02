require 'concurrent'

module Peribot
  # This class is used to create processor groups. A group consists of a number
  # of "processors" (tasks) that are run in parallel. A message is sent into
  # the group using the {#accept} method, which dispatches it to all processors
  # simultaneously. All processing occurs asynchronously on background threads.
  #
  # This class is designed and intended for internal use within Peribot. It is
  # not considered public, and the API is not guaranteed to be stable.
  #
  # Peribot uses processor groups for sending messages. New groups are created
  # by creating new instances of this class.
  class ProcessorGroup
    include ErrorHelpers

    # Create a new processor group.
    #
    # @param bot [Peribot::Bot] A Peribot instance
    def initialize(bot)
      @bot = bot
      @tasks = []
    end

    attr_reader :tasks

    # Register a task with this processor group. The given task will be
    # instantiated and used to process the message. Tasks will only be
    # registered once regardless of how many times this method is called with
    # one.
    #
    # @param task [Class] A class with a #process method taking a message
    def register(task)
      tasks << task unless tasks.include? task
    end

    # Dispatch a message to all tasks registered to this group.
    #
    # @param msg [Hash] The message to process
    # @return [Array<Concurrent::IVar>] An array of promises to wait on
    def accept(msg)
      tasks.map do |task|
        Concurrent::Promise.execute { task.new(bot).process(msg) }
                           .rescue { |e| log_failure error: e, message: msg }
      end
    end

    private

    attr_reader :bot
  end
end
