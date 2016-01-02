require 'spec_helper'
require 'shared_examples/middleware'

describe Peribot::Preprocessor do
  it_behaves_like 'a middleware chain'

  describe '#end_action' do
    let(:message) { { 'group_id' => '1234', 'text' => 'Test' } }

    it 'dispatches messages to services' do
      expect(Peribot::Services).to receive(:dispatch).with(message)
      Peribot::Preprocessor.instance.end_action(message)
    end
  end
end
