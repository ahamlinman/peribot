require 'spec_helper'

describe Peribot::Configuration::Builder do
  let(:instance) { Peribot::Configuration::Builder.new }

  describe '#build' do
    it 'returns a Peribot::Configuration object' do
      expect(instance.build).to be_instance_of(Peribot::Configuration)
    end

    it 'freezes configuration objects' do
      expect(instance.build).to be_frozen
    end
  end

  describe '#conf_directory' do
    it 'sets the configuration directory' do
      instance.conf_directory 'test'
      expect(instance.build.conf_directory).to eq('test')
    end
  end

  describe '#store_directory' do
    it 'sets the store directory' do
      instance.store_directory 'test'
      expect(instance.build.store_directory).to eq('test')
    end
  end
end
