module Peribot
  # Superclass representing a processor task. Processor tasks receive messages
  # (via the {#process} method), change them as appropriate, and pass them on
  # to other tasks or other parts of the Peribot message chain.
  #
  # It is suggested that tasks extend this class for convenience, though any
  # class that includes a {#process} method taking a message should be
  # acceptable. Keep in mind that all instances are initialized with a
  # {Peribot::Bot} that provides various services for tasks and other
  # components.
  class Processor
    # Create a new instance of this middleware task.
    #
    # @param bot [Peribot] A Peribot instance
    def initialize(bot)
      @bot = bot
    end

    # Process a message within this task. This method may perform one of the
    # following actions:
    # * Return the message unchanged
    # * Return a modified message
    # * Raise an error to log it and prevent further processing
    # * Call stop_processing to silently prevent further processing (not
    #   recommended in most cases - sender tasks are a major exception)
    #
    # @param _message_ [Hash] The message to be processed
    # @return [Hash] A message, potentially changed by this task
    def process(_message_)
      fail "process method not implemented in #{self.class}"
    end

    # Stop further processing of this message in this pipeline. This prevents
    # any further tasks in the processor chain, including the end action, from
    # running. However, it will not raise any error or give any other
    # indication that processing has stopped. Use with caution during
    # preprocessing and postprocessing, and feel free to use in sender tasks if
    # you are sure that the message has been sent properly and no other senders
    # will need it.
    #
    # Within the preprocessing and postprocessing chains, this is effectively
    # the same as discarding a message. Thus, this method may also be called
    # as discard_message.
    def stop_processing
      fail Peribot::ProcessorChain::Stop
    end
    alias discard_message stop_processing
  end
end
