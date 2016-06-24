require 'spec_helper'

describe Peribot::Util::BlockHashBuilder do
  it 'builds hashes using blocks' do
    hash = Peribot::Util::BlockHashBuilder.build do
      key 'value'
      group { key 'value' }
    end
    expected = { 'key' => 'value', 'group' => { 'key' => 'value' } }

    expect(hash).to eq(expected)
  end

  describe '#respond_to_missing?' do
    it 'says we respond to everything' do
      expect(Peribot::Util::BlockHashBuilder.new.respond_to?(:asdfqwer))
        .to be_truthy
    end
  end
end
