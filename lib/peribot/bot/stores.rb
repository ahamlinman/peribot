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
      # Obtain a store based on a given key.
      #
      # @param key [String] The key for the store
      # @return [Concurrent::Atom] A Concurrent::Atom representing the store
      def store(key)
        @store_map[key.to_s]
      rescue NoMethodError
        raise 'No store directory defined'
      end

      private

      # (private)
      #
      # Set the store directory from which store files are saved to and loaded
      # from. This is effectively done by create a thread-safe map that can be
      # used to retrieve Atoms backed by these files.
      #
      # @param dir [String] The directory to save/load from
      def setup_store_directory(dir)
        fail 'No store directory defined' unless dir

        # Concurrent::Map#initialize accepts a block that will be called to
        # initialize nonexistent values. The documentation doesn't make this
        # obvious, but it seems to simply be incomplete at this time (as of
        # 2016-01-09).
        @store_map = Concurrent::Map.new(&generate_store_atom(dir))
      end

      # (private)
      #
      # Return a proc that, when called, will create a Concurrent::Atom backed
      # by a PStore.
      #
      # @param dir [String] The directory to save/load PStore files from
      # @return [Proc] A proc to make atoms with store files in dir
      def generate_store_atom(dir)
        proc do |map, key|
          filename = store_filename dir, key
          # PStore#new's second parameter enables thread safety (though perhaps
          # this is overkill?)
          store = PStore.new filename, true
          initial = store.transaction { store[:data] }

          atom = Concurrent::Atom.new initial
          atom.add_observer(&generate_store_observer(store))

          map[key] = atom
        end
      end

      # (private)
      #
      # Get the path to a persistent store file based on a directory and key.
      #
      # @param dir [String] The directory of PStore files
      # @param key [String] The name of the store
      # @return [String] The full path to the store file
      def store_filename(dir, key)
        File.expand_path(File.join(dir, "#{key}.store"))
      end

      # (private)
      #
      # Generate an observer for the given store.
      #
      # @param store [PStore] The store to save data to on update
      # @return [Proc] An observer proc that updates the store's data
      def generate_store_observer(store)
        proc do |_, _, new_value|
          store.transaction { store[:data] = new_value }
        end
      end
    end
  end
end
