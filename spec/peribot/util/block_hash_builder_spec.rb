require 'spec_helper'

describe Peribot::Util::BlockHashBuilder do
  it 'builds hashes using blocks' do
    hash = described_class.build do
      key 'value'
      group { key 'value' }
    end
    expected = { 'key' => 'value', 'group' => { 'key' => 'value' } }

    expect(hash).to eq(expected)
  end

  it 'freezes the returned value' do
    hash = described_class.build { key 'value' }
    expect(hash).to be_frozen
  end

  describe '#respond_to_missing?' do
    it 'says we respond to everything' do
      expect(described_class.new.respond_to?(:asdfqwer)).to be_truthy
    end
  end
end
