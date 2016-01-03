require 'spec_helper'

describe Peribot::Configuration do
  let(:instance) { Peribot::Configuration.new }

  it 'has a configuration directory parameter' do
    instance.conf_directory = 'test'
    expect(instance.conf_directory).to eq('test')
  end

  it 'has a store directory parameter' do
    instance.store_directory = 'test'
    expect(instance.store_directory).to eq('test')
  end
end
