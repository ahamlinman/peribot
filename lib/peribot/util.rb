require 'peribot/util/block_hash_builder'
require 'peribot/util/key_value_atom'

module Peribot
  # This module provides general utility and helper classes for Peribot.
  module Util
    module_function

    # Take an array of replies, and:
    #
    #   * flatten it out completely
    #   * remove any nil replies
    #   * convert string-only replies to Peribot-formatted message hashes
    #     (based on the original message provided)
    #
    # Then, yield each resulting message to the provided block.
    #
    # The purpose of this function is to make construction of higher-level
    # Peribot processors easier. A higher-level processor can abstract over
    # some details of Peribot's internal processing structure by allowing a
    # synchronous return of nil, a single message, or an array of messages.
    # This function provides an easy, standard way to map that back into to the
    # lower-level callback-based world.
    def process_replies(replies, original, &accept)
      outputs = replies.flatten.compact.map do |reply|
        if reply.instance_of? String
          {
            service: original[:service],
            group: original[:group],
            text: reply
          }
        else
          reply
        end
      end

      outputs.each(&accept)
    end
  end
end
