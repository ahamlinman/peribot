module Peribot
  # ProcessorRegistry provides an ability for components to "register"
  # processors that may be used by the bot to process messages. Processor
  # chains and groups can be created using lists obtained from the registries.
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

    # Obtain a list of processors that have been previously registered. This
    # method is also named "tasks" for backwards compatibility, however that
    # form is deprecated.
    #
    # @return An array of processors
    def list
      @processors.keys
    end
    alias tasks list
  end
end
