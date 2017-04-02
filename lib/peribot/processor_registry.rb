module Peribot
  # ProcessorRegistry provides an ability for components to "register"
  # processors that may be used by the bot to process messages. New processor
  # chains and groups can be created from the list obtained from the registry.
  class ProcessorRegistry
    # Create a new processor registry.
    def initialize
      @processors = {}
    end

    # Register a processor for use by the bot. The given processor will only be
    # registered once, regardless of how many times this method is called with
    # it.
    #
    # @return True if the registration was new, false if not
    def register(processor)
      return false if @processors.include? processor
      @processors[processor] = true
    end

    # Obtain a list of processors that have been previously registered.
    #
    # @return An array of processors
    def list
      @processors.keys
    end
    alias tasks list
  end
end
