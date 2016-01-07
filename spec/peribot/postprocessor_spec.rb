require 'spec_helper'

describe Peribot::Postprocessor do
  describe '.instance' do
    it 'forwards messages to the sender chain after processing' do
      message = { 'test' => true }
      expect(Peribot::Sender.instance).to receive(:accept).with(message)

      Peribot::Postprocessor.instance.accept(message).value
    end
  end
end
