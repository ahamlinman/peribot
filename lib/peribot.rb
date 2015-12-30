require 'peribot/middleware'
require 'peribot/version'

# The top-level namespace for Peribot. Some global functionality is also
# provided as part of this module.
module Peribot
  module_function

  # A simple logging function for use by Peribot components. Outputs the given
  # message to stderr with a "[Peribot]" prefix.
  #
  # @param message Text to output to stderr
  def log(message)
    $stderr.puts "[Peribot] #{message}"
  end
end
