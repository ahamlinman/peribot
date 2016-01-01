require 'peribot/middleware'

module Peribot
  # Peribot's postprocessor chain, which receives messages from services and
  # applies necessary processing before forwarding them to the sending chain.
  #
  # @see Peribot::Middleware::Chain
  class Postprocessor < Peribot::Middleware::Chain
    # After postprocessing, forwards messages to the sender chain. The sender
    # chain handles sending fully processed messages to GroupMe.
    #
    # @param message [Hash] The processed message
    def end_action(message)
      Peribot::Sender.instance.async.accept message
    end
  end
end
