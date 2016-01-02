require 'peribot/middleware'

module Peribot
  # Peribot's preprocessor chain, which receives all messages from GroupMe and
  # performs necessary processing on them before dispatching them to services.
  #
  # @see Peribot::Middleware::Chain
  class Preprocessor < Peribot::Middleware::Chain
    def end_action(message)
      Peribot::Services.dispatch message
    end
  end
end
