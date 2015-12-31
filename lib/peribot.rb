require 'peribot/middleware'
require 'peribot/sender'
require 'peribot/version'

# The top-level namespace for Peribot. Some global functionality is also
# provided as part of this module.
module Peribot
  module_function

  # Obtain an instance of the sender chain, which receives messages after
  # postprocessing and sends them to GroupMe.
  #
  # @return [Peribot::Sender] The sender instance
  def sender
    @sender ||= Peribot::Sender.new
  end

  # A simple logging function for use by Peribot components. Outputs the given
  # message to stderr with a "[Peribot]" prefix.
  #
  # @param message Text to output to stderr
  def log(message)
    $stderr.puts "[Peribot] #{message}"
  end
end
