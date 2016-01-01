require 'peribot/services/base'

module Peribot
  # This module contains functionality for creating and working with services
  # in Peribot, which receive and can reply to messages from GroupMe. These
  # services are where most serious work in Peribot should be performed.
  module Services
    @list = []
    class << self; attr_reader :list; end
  end
end
