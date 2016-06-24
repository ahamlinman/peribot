require 'pstore'

module Peribot
  class Bot
    # This module provides the implementation of Peribot's persistent storage
    # facilities. When a store is requested, a Concurrent::Atom is created that
    # is automatically backed by a PStore. Stored values can be changed using
    # methods from Concurrent::Atom, such as swap. Changes are persisted as
    # soon as they succeed. Atoms are created (and their contents loaded from
    # storage) lazily as requested by components.
    module Stores
      DEFAULT_STORE_FILE = File.expand_path 'peribot.pstore'

      # Obtain a map of stores.
      def stores
        # Concurrent::Map#initialize accepts a block that will be called to
        # initialize nonexistent values. The documentation doesn't make this
        # obvious, but it seems to simply be incomplete at this time (as of
        # 2016-01-09).
        @stores ||= Concurrent::Map.new do |map, key|
          initial = pstore.transaction { pstore[key] }

          atom = Peribot::Util::KeyValueAtom.new
          atom.swap { initial.freeze } if initial
          atom.add_observer(&generate_store_observer_proc(key))

          map[key] = atom
        end
      end

      # Obtain the name of the file in which stores are being saved.
      def store_file
        @store_file ||= ENV['PERIBOT_STORE'] || DEFAULT_STORE_FILE
      end

      attr_writer :store_file

      private

      # (private)
      #
      # Obtain or create a PStore to save data from stores.
      def pstore
        # PStore#new's second parameter enables thread safety (though perhaps
        # this is overkill?)
        @pstore ||= PStore.new store_file, true
      end

      # (private)
      #
      # Generate an observer that saves data under the given key in the shared
      # PStore.
      #
      # @param key The key under which data will be saved
      # @return [Proc] An observer proc that updates the store's data
      def generate_store_observer_proc(key)
        proc do |_, _, new_value|
          pstore.transaction { pstore[key] = new_value }
        end
      end
    end
  end
end
