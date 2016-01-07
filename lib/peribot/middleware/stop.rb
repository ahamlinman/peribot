module Peribot
  module Middleware
    # An exception class that middleware tasks can use to stop message
    # processing without logging an error.
    class Stop < RuntimeError
    end
  end
end
