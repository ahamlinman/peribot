require 'spec_helper'
require 'shared_examples/middleware'

describe Peribot::Postprocessor do
  it_behaves_like 'a middleware chain'

  describe '#end_action' do
    it 'forwards messages to the sender chain' do
      message = { 'test' => true }
      expect(Peribot.sender).to receive(:accept).with(message)

      Peribot::Postprocessor.new.end_action(message).value
    end
  end
end
