require 'spec_helper'
require 'tmpdir'

describe Peribot::Bot::Stores do
  let(:test_class) do
    Class.new do
      include Peribot::Bot::Stores
      def setup(store_dir)
        setup_store_directory store_dir
        self
      end
    end
  end

  let(:tmpdir) { Dir.mktmpdir }

  context 'with no store directory set up' do
    let(:instance) { test_class.new }

    it 'raises an error when getting a store' do
      expect { instance.stores[''] }.to raise_error(
        'No store directory defined')
    end
  end

  context 'when setting up a nil store directory' do
    let(:instance) { test_class.new.setup nil }

    it 'raises an error upon setup' do
      expect { instance }.to raise_error('No store directory defined')
    end
  end

  context 'with a store directory given' do
    let(:instance) { test_class.new.setup tmpdir }

    it 'returns a Concurrent::Atom' do
      expect(instance.stores['test']).to be_a_kind_of(Concurrent::Atom)
    end

    it 'returns the same atom for a given key' do
      expect(instance.stores['test']).to equal(instance.stores['test'])
    end

    it 'defaults to an empty hash as its value' do
      expect(instance.stores['test'].value).to eq({})
    end

    it 'creates a persistent store file when writing' do
      instance.stores['test'].swap { 'It works!' }

      file = File.join tmpdir, 'test.store'
      expect(File.exist?(file)).to be true
    end

    it 'returns atoms that allow array-style access' do
      instance.stores['mystore']['key'] = 'value'

      file = File.join tmpdir, 'mystore.store'
      expect(File.exist?(file)).to be true

      store = PStore.new file
      value = store.transaction { store[:data] }
      expect(value).to eq('key' => 'value')
    end

    it 'reads from store files when they exist' do
      file = File.join tmpdir, 'sample.store'
      store = PStore.new file
      store.transaction { store[:data] = { 'key' => 'value' } }

      expect(instance.stores['sample']['key']).to eq('value')
    end
  end
end
