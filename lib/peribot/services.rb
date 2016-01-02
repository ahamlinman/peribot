require 'peribot/services/base'

require 'concurrent'

module Peribot
  # This module contains functionality for creating and working with services
  # in Peribot, which receive and can reply to messages from GroupMe. These
  # services are where most serious work in Peribot should be performed.
  module Services
    @list = []
    class << self; attr_reader :list; end

    module_function

    # Dispatch a message from the preprocessor to all services. This returns a
    # future whose value will be an array of promise chains created by the
    # services.
    #
    # @param message [Hash] The message to process
    # @return [Concurrent::Future] The future used for dispatching
    def dispatch(message)
      Concurrent::Future.execute do
        @list.map do |service|
          service.new.accept message
        end
      end
    end
  end
end
