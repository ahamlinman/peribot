module Peribot
  module Util
    # Build a Hash by executing a block. This allows a DSL-style
    # configuration for bots.
    class BlockHashBuilder
      # Construct a hash from the configuration in the provided block.
      def self.build(&block)
        hb = new
        hb.instance_eval(&block)
        hb.finalize!
      end

      # Create a new builder
      def initialize
        @_values = {}
      end

      # Assign a value to a key, or build a subhash.
      def method_missing(key, value = nil, &block)
        @_values[key.to_s] = if block_given?
                               self.class.build(&block)
                             else
                               value
                             end
      end

      # Ensure that any valid method name works.
      def respond_to_missing?(*)
        true
      end

      # Return the hash that we have built up.
      def finalize!
        @_values.freeze
      end
    end
  end
end
