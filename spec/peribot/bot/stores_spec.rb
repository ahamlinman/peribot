require 'spec_helper'
require 'tmpdir'

describe Peribot::Bot::Stores do
  let(:test_class) do
    Class.new do
      include Peribot::Bot::Stores
      def initialize(filename = nil)
        @store_file = filename
      end
    end
  end

  context 'with no explicit store file' do
    let(:instance) { test_class.new }

    context 'with a filename in the environment' do
      before(:all) { ENV['PERIBOT_STORE'] = '/path/to/peribot.pstore' }
      after(:all) { ENV['PERIBOT_STORE'] = nil }

      it 'uses the filename as the store file location' do
        expect(instance.store_file).to eq('/path/to/peribot.pstore')
      end
    end

    context 'without a filename in the environment' do
      it 'uses the peribot.pstore file in the working directory' do
        expect(instance.store_file).to eq(File.expand_path('peribot.pstore'))
      end
    end
  end

  context 'with an explicit store file' do
    let(:tmp_file) { File.join Dir.mktmpdir, 'peribot.pstore' }
    let(:instance) { test_class.new tmp_file }

    it 'returns a Concurrent::Atom' do
      expect(instance.stores['test']).to be_a_kind_of(Concurrent::Atom)
    end

    it 'returns the same atom for a given key' do
      expect(instance.stores['test']).to equal(instance.stores['test'])
    end

    it 'defaults to an empty hash as its value' do
      expect(instance.stores['test'].value).to eq({})
    end

    it 'saves to the configured store file' do
      instance.stores['test'].swap { 'It works!' }

      store = PStore.new tmp_file
      value = store.transaction { store['test'] }

      expect(value).to eq('It works!')
    end

    it 'reads initial values from existing store files' do
      store = PStore.new tmp_file
      store.transaction { store['sample'] = { 'key' => 'value' } }

      expect(instance.stores['sample']['key']).to eq('value')
    end

    it 'returns atoms that allow array-style access' do
      instance.stores['mystore']['key'] = 'value'
      expect(instance.stores['mystore']['key']).to eq('value')
    end
  end
end
