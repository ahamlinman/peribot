require 'spec_helper'

describe Peribot::Util::KeyValueAtom do
  let(:instance) { Peribot::Util::KeyValueAtom.new }

  it 'provides the functionality of Concurrent::Atom' do
    expect(instance).to be_a_kind_of(Concurrent::Atom)
  end

  describe '#initialize' do
    it 'initializes the atom value to an empty hash' do
      expect(instance.value).to eq({})
    end
  end

  describe '#[]' do
    it 'gets values in the atom value object' do
      instance.swap { { 'key' => 'value' } }
      expect(instance['key']).to eq('value')
    end
  end

  describe '#[]=' do
    it 'sets values in the atom value object' do
      instance['key'] = 'value'
      expect(instance.value).to eq('key' => 'value')
    end
  end
end
