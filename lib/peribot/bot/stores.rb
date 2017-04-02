require 'concurrent'
require 'pstore'

module Peribot
  class Bot
    # Bot::Stores provides the implementation of Peribot's persistent storage
    # facilities. When a store is requested, Peribot creates a special map that
    # automatically provides lock-free thread safety and backing by a PStore.
    # The map is an extension of Concurrent::Atom from concurrent-ruby, thus
    # all methods of that class are available as well. Maps are created (and
    # their contents loaded from storage) lazily as requested by processors.
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
          atom.add_observer do |_, _, new_value|
            pstore.transaction { pstore[key] = new_value }
          end

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
    end
  end
end
