module Peribot
  module Middleware
    # An exception class that middleware tasks can use to stop message
    # processing without logging an error. It would be reasonable to argue that
    # an exception should not be used for this purpose, as it is not
    # representative of a failed state. However, I believe it is the simplest
    # solution for this purpose given the nature of the promise chains that
    # middleware chains are built on. This helps ensure that tasks are not
    # needlessly run and allows them to assume they will receive proper
    # messages, rather than a value like nil.
    #
    # It is suggested that this be used with caution and only for things that
    # administrators truly do not need to see in logs, such as the sender chain
    # being stopped after a message has been sent. Sender chains are the most
    # obvious (and intended) use case, though others might be appropriate as
    # well.
    class Stop < RuntimeError
    end
  end
end
