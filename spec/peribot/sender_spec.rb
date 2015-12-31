require 'spec_helper'
require 'shared_examples/middleware'

describe Peribot::Sender do
  it_behaves_like 'a middleware chain'
end
