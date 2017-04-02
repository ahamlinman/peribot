module Peribot
  # ProcessorChain is a processor that composes multiple sub-processors into a
  # serial pipeline, to allow for filtering, transformation, and other use
  # cases. Sub-processors may choose to drop messages (by not yielding to their
  # acceptor) or produce multiple messages from a single input (by yielding
  # more than once). In the latter case, the chain will fork and each message
  # will be individually processed by the remaining sub-processors in the
  # chain.
  #
  # This class is designed and intended for internal use within Peribot (to
  # implement preprocessing and postprocessing of messages). It is not
  # considered public, and the API is not guaranteed to be stable.
  class ProcessorChain
    include ErrorHelpers

    # Create a new processor chain.
    #
    # @param processors An array of processors
    def initialize(processors)
      @processors = processors.dup.freeze
    end

    # Process a message using the chain.
    #
    # @param bot [Peribot::Bot] The bot instance for use by sub-processors
    # @param message The message to process
    # @yield Messages output by processors in the chain
    def call(bot, message, &acceptor)
      if @processors.empty?
        yield message
        return
      end

      begin
        @processors.first.call bot, message do |output|
          self.class.new(@processors.drop(1)).call bot, output, &acceptor
        end
      rescue => e
        log_failure error: e, message: message, logger: bot.method(:log)
      end
    end

    private

    # Required by ErrorHelpers, unfortunately.
    def bot; end
  end
end
