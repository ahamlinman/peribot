require 'spec_helper'

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
      expect { instance.store '' }.to raise_error('No store directory defined')
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
      expect(instance.store('test')).to be_instance_of(Concurrent::Atom)
    end

    it 'returns the same atom for a given key' do
      expect(instance.store('test')).to equal(instance.store('test'))
    end

    it 'defaults to an empty hash as its value' do
      expect(instance.store('test').value).to eq({})
    end

    it 'creates a persistent store file when writing' do
      instance.store('test').swap { 'It works!' }

      file = File.join tmpdir, 'test.store'
      expect(File.exist?(file)).to be true
    end
  end
end
