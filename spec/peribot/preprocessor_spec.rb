require 'spec_helper'

describe Peribot::Preprocessor do
  describe '.instance' do
    let(:message) { { 'group_id' => '1234', 'text' => 'Test' } }

    it 'dispatches messages to services after processing' do
      expect(Peribot::Services).to receive(:dispatch).with(message)
      Peribot::Preprocessor.instance.accept(message).value
    end
  end
end
