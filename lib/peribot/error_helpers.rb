module Peribot
  # A module to provide standard functionality for printing error messages
  # within Peribot components. It assumes the presence of a #bot accessor
  # method that returns a Peribot instance with a #log method.
  #
  # This module is designed primarily for internal use.
  module ErrorHelpers
    private

    # (private)
    #
    # Log an error to the local Peribot instance.
    #
    # @param error [Exception] The exception that occurred
    # @param message [Hash] The message that caused the exception
    # @param logger [Proc] A method to log the error with
    def log_failure(error: nil, message: nil, logger:)
      msg = "(#{Time.now}) Error in #{self.class}"
      msg << "\n  => message = #{message}" if message
      if error
        msg << "\n  => exception = #{error.inspect}"
        msg << "\n  => backtrace:\n#{indent_lines error.backtrace}"
      end

      logger.call msg
    end

    # (private)
    #
    # Indent a set of lines by a given amount.
    #
    # @param lines [Array<String>] The lines to indent
    # @param indent [Integer] The number of spaces to indent with
    def indent_lines(lines, indent: 6)
      lines.map { |line| (' ' * indent) + line }.join("\n")
    end
  end
end
