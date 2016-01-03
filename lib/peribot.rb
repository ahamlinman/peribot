require 'peribot/configuration'
require 'peribot/middleware'
require 'peribot/preprocessor'
require 'peribot/postprocessor'
require 'peribot/sender'
require 'peribot/services'
require 'peribot/version'

require 'concurrent'
require 'docile'
require 'pstore'
require 'yaml'

# The top-level namespace for Peribot. Some global functionality is also
# provided as part of this module.
module Peribot
  class << self
    attr_reader :meta_config
  end

  module_function

  # A simple logging function for use by Peribot components. Outputs the given
  # message to stderr with a "[Peribot]" prefix.
  #
  # @param message Text to output to stderr
  def log(message)
    $stderr.puts "[Peribot] #{message}"
  end

  # Execute a DSL to configure a Peribot instance. This is used to set
  # directories for configuration and persistent store files.
  def configure(&block)
    builder = Peribot::Configuration::Builder.new
    @meta_config = Docile.dsl_eval(builder, &block).build

    reset_config_builder
    reset_store_map

    nil
  end

  # Retrieve a read-only object containing information read from the
  # configuration directory set via the configure method.
  def config
    @config_builder.value || (fail @config_builder.reason)
  end

  # Retrieve a Concurrent::Atom backed by a file in the store directory set via
  # the configure method.
  #
  # @param key [String] A unique key representing the store
  def store(key)
    @store_map[key.to_s]
  end

  class << self
    private

    # (Re-)Set the Concurrent::Delay that is used to lazily build the Peribot
    # global configuration object.
    def reset_config_builder
      @config_builder = Concurrent::Delay.new do
        setup_config(@meta_config).freeze
      end
    end

    # Build the configuration object for this Peribot instance by reading all
    # of the files in the configuration directory and creating a hash out of
    # them.
    #
    # @param meta_config [Peribot::Configuration] The meta_config object
    def setup_config(meta_config)
      fail 'No config directory defined' unless meta_config.conf_directory

      files = Dir[File.join(meta_config.conf_directory, '*.conf')]
      files.reduce({}) do |config, file|
        basename = File.basename file, '.*'
        config.merge(basename => load_config_file(file))
      end
    end

    # Load a configuration file.
    #
    # @param file [String] The name of the file to load
    def load_config_file(file)
      YAML.load_file file
    end

    # (Re-)Set the Concurrent::Map that is used to store all of the
    # Concurrent::Atom store objects.
    def reset_store_map
      # Concurrent::Map#initialize accepts a block that will be called to
      # initialize nonexistent values. The documentation for Map appears to be
      # incomplete and doesn't really show this, but it is evident from the
      # code itself.
      @store_map = Concurrent::Map.new(&method(:create_store_atom))
    end

    # Create a new Concurrent::Atom to be used for persistent storage. This is
    # called by the Concurrent::Map implementation when a store is requested
    # for a nonexistent key. The Atom created by this method will be saved in
    # the map and used for future accesses of the given key.
    #
    # @param map [Concurrent::Map] The store map
    # @param key [String] The key representing the store
    def create_store_atom(map, key)
      file = store_filename key
      store = get_store file
      initial = store.transaction { store[:data] }

      atom = Concurrent::Atom.new initial
      atom.add_observer(&create_store_observer(store))

      map[key] = atom
    end

    # Get the path to a persistent store file based on a key.
    #
    # @param key [String] The name of the store
    def store_filename(key)
      dir = @meta_config.store_directory
      File.expand_path(File.join(dir, "#{key}.store"))
    end

    # Load the data in a persistent store file based on a file path.
    #
    # @param file [String] The path to the file
    def get_store(file)
      # The second parameter makes the PStore thread-safe.
      PStore.new file, true
    end

    # Construct an observer for a given store.
    #
    # @param store [PStore] The store to save data to on update.
    def create_store_observer(store)
      proc do |_, _, new_value|
        store.transaction { store[:data] = new_value }
      end
    end
  end
end
