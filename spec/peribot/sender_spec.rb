require 'spec_helper'

describe Peribot::Sender do
  describe '.instance' do
    it 'returns a middleware chain' do
      instance = Peribot::Sender.instance
      expect(instance).to be_instance_of(Peribot::Middleware::Chain)
    end
  end
end
