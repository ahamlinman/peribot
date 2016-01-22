require 'peribot/bot'
require 'peribot/middleware'
require 'peribot/processor_chain'
require 'peribot/service'
require 'peribot/version'

# The top-level namespace for Peribot.
module Peribot
  module_function

  # A simple, short alias to create a new {Peribot::Bot} instance with the
  # arguments given.
  #
  # @example Create a new bot
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
