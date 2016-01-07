require 'peribot/middleware'

module Peribot
  # Peribot's sender chain, which is responsible for sending messages from
  # Peribot to GroupMe. It is possible for multiple senders to be useful - e.g.
  # a separate sender task may be used to like messages, or multiple messaging
  # services might be possible in the future.
  class Sender
    class << self
      # Create a chain to be used for sending.
      def instance
        @instance ||= Peribot::Middleware::Chain.new(Peribot)
      end
    end
  end
end
