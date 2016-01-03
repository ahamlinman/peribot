require 'spec_helper'

describe Peribot do
  it 'has a version number' do
    expect(Peribot::VERSION).not_to be nil
  end

  it 'has a meta_config property' do
    expect(Peribot).to respond_to(:meta_config)
  end

  describe '.log' do
    it 'prints to stderr' do
      expect { Peribot.log 'stuff' }.to output("[Peribot] stuff\n").to_stderr
    end
  end

  describe '.configure' do
    it 'sets the Peribot.meta_config property' do
      Peribot.configure do
        conf_directory 'conf/test'
        store_directory 'store/test'
      end

      expect(Peribot.meta_config.conf_directory).to eq('conf/test')
      expect(Peribot.meta_config.store_directory).to eq('store/test')
    end
  end
end
