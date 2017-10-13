require 'concurrent'

module Peribot
  # ProcessorGroup is a processor that composes multiple sub-processors by
  # fanning received messages out to each of them. Individual processors (and,
  # transitively, the processor group constructed from them) may produce
  # between zero and many messages depending on how often they yield to the
  # provided acceptor.
  #
  # This class is designed and intended for internal use within Peribot (to
  # implement dispatching of messages to services and senders). It is not
  # considered public, and the API is not guaranteed to be stable.
  class ProcessorGroup
    include ErrorHelpers

    # Create a new processor group.
    #
    # @param processors An array of processors
    def initialize(processors)
      @processors = processors
    end

    # Process a message using the group.
    #
    # @param bot [Peribot::Bot] The bot instance for use by sub-processors
    # @param message The message to process
    # @yield Messages output by processors in the group
    def call(bot, message, &acceptor)
      @processors.map do |p|
        Concurrent::Future.execute do
          begin
            p.call(bot, message, &acceptor)
          rescue StandardError => e
            log_failure error: e, message: message,
                        logger: bot.public_method(:log)
          end
        end
      end
    end
  end
end
