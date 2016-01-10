require 'spec_helper'

describe Peribot do
  it 'has a version number' do
    expect(Peribot::VERSION).not_to be nil
  end

  describe '.new' do
    it 'creates a Peribot::Bot' do
      bot = Peribot.new config_directory: '', store_directory: ''
      expect(bot).to be_instance_of(Peribot::Bot)
    end
  end
end
