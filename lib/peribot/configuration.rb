module Peribot
  # A class to hold configuration options for a Peribot instance, such as the
  # locations of directories for configuration and persistent store files.
  class Configuration
    attr_accessor :conf_directory, :store_directory
  end
end
