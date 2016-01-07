require 'peribot/middleware'

module Peribot
  # Peribot's preprocessor chain, which receives all messages from GroupMe and
  # performs necessary processing on them before dispatching them to services.
  #
  # @see Peribot::Middleware::Chain
  class Preprocessor
    class << self
      # Create a chain to be used for preprocessing.
      def instance
        @instance ||= Peribot::Middleware::Chain.new(Peribot) do |msg|
          Peribot::Services.dispatch msg
        end
      end
    end
  end
end
