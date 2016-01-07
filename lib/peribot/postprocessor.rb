require 'peribot/middleware'

module Peribot
  # Peribot's postprocessor chain, which receives messages from services and
  # applies necessary processing before forwarding them to the sending chain.
  class Postprocessor
    class << self
      # Create a chain to be used for postprocessing.
      def instance
        @instance ||= Peribot::Middleware::Chain.new do |msg|
          Peribot::Sender.instance.accept msg
        end
      end
    end
  end
end
