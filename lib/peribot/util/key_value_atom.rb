require 'concurrent'

module Peribot
  module Util
    # A simple Concurrent::Atom that acts as a key-value store (basically, a
    # Hash without any additional fancy functionality). This provides a simple
    # thread-safe key-value store while still giving users the full flexibility
    # of a Concurrent::Atom if desired.
    #
    # In certain places where a Concurrent::Map would arguably be better for
    # this purpose, this is used instead due to the observer functionality that
    # it provides. In particular, observers are an important part of the data
    # store functionality.
    class KeyValueAtom < Concurrent::Atom
      # Initialize the atom with a default value consisting of a frozen empty
      # Hash.
      def initialize
        super({}.freeze)
      end

      # Considering the value of this Atom as a Hash, access the value of a
      # particular key.
      #
      # @param key The key to access
      def [](key)
        value[key]
      end

      # Considering the value of this Atom as a Hash, update the value of a
      # particular key in a thread-safe way. This should result in the value of
      # the Atom being a frozen Hash that contains the given value for the
      # given key along with all other original values.
      #
      # @param key The key to update
      # @param value The value to assign to the key
      def []=(key, value)
        swap { |v| v.merge(key => value).freeze }
      end
    end
  end
end
