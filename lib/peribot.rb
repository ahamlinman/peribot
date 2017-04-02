require 'peribot/bot'
require 'peribot/error_helpers'
require 'peribot/processor'
require 'peribot/processor_chain'
require 'peribot/processor_group'
require 'peribot/processor_registry'
require 'peribot/service'
require 'peribot/util'
require 'peribot/version'

# The top-level namespace for Peribot.
module Peribot
  module_function

  # A simple, short alias to create a new {Peribot::Bot} instance with the
  # arguments given. Configuration and store files can be given
  # explicitly as arguments, or are pulled from the environment by default. See
  # the documentation for {Peribot::Bot#initialize} for more information.
  #
  # @example Create a new bot using configuration from the environment
  #   # ENV['PERIBOT_CONFIG'] and ENV['PERIBOT_STORE'] are defined
  #   Peribot.new
  #
  # @example Create a new bot with explicit configuration
  #   Peribot.new(
  #     config_file: File.expand_path('/my/config.yml'),
  #     store_file: File.expand_path('/my/peribot.pstore')
  #   )
  #
  # @see Peribot::Bot#initialize
  # @return [Peribot::Bot]
  def new(*args)
    Peribot::Bot.new(*args)
  end
end
