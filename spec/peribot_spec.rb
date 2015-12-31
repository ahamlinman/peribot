require 'spec_helper'

describe Peribot do
  it 'has a version number' do
    expect(Peribot::VERSION).not_to be nil
  end

  describe '.sender' do
    it 'returns a sender chain instance' do
      expect(Peribot.sender).to be_instance_of(Peribot::Sender)
    end
  end

  describe '.log' do
    it 'prints to stderr' do
      expect { Peribot.log 'stuff' }.to output("[Peribot] stuff\n").to_stderr
    end
  end
end
