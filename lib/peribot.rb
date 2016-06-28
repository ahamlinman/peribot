require 'peribot/bot'
require 'peribot/error_helpers'
require 'peribot/processor'
require 'peribot/processor_chain'
require 'peribot/processor_group'
require 'peribot/service'
require 'peribot/util'
require 'peribot/version'

# The top-level namespace for Peribot.
module Peribot
  module_function

  # A simple, short alias to create a new {Peribot::Bot} instance with the
  # arguments given. Configuration and store directories can be given
  # explicitly as arguments, or are pulled from the environment by default. See
  # the documentation for {Peribot::Bot#initialize} for more information.
  #
  # @example Create a new bot using configuration from the environment
  #   # ENV['PERIBOT_CONFIG_DIR'] and ENV['PERIBOT_STORE_DIR'] are defined
  #   Peribot.new
  #
  # @example Create a new bot with explicit configuration
  #   Peribot.new(
  #     config_directory: File.expand_path('my/config/dir'),
  #     store_directory: File.expand_path('my/store/dir')
  #   )
  #
  # @see Peribot::Bot#initialize
  # @return [Peribot::Bot]
  def new(*args)
    Peribot::Bot.new(*args)
  end
end
