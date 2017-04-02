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

    it 'freezes the initial value' do
      expect(instance.value).to be_frozen
    end
  end

  describe '#[]' do
    it 'gets values in the atom value object' do
      instance.swap { { 'key' => 'value' } }
      expect(instance['key']).to eq('value')
    end

    it 'returns nil as a default value' do
      expect(instance['default']).to eq(nil)
    end
  end

  describe '#[]=' do
    it 'sets values in the atom value object' do
      instance['key'] = 'value'
      expect(instance.value).to eq('key' => 'value')
    end

    it 'merges multiple values into the atom value object' do
      instance['great'] = 'test'
      instance['case'] = true
      expect(instance.value).to eq('great' => 'test', 'case' => true)
    end

    it 'freezes the atom value object after setting' do
      instance['frozen'] = true
      expect(instance.value).to be_frozen
    end
  end
end
