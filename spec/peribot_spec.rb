require 'spec_helper'
require 'tmpdir'

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

  describe '.when_configured' do
    before(:each) { Peribot.reset }

    it 'runs blocks once Peribot is configured' do
      value = nil
      Peribot.when_configured { value = 'It worked!' }
      Peribot.configure {}.value

      expect(value).to eq('It worked!')
    end
  end

  describe '.config' do
    context 'before configuration' do
      before(:each) { Peribot.reset }

      it 'raises an error' do
        expect { Peribot.config }.to raise_error('Peribot is not configured')
      end
    end

    context 'with no conf_directory set' do
      before(:each) { Peribot.configure {} }

      it 'raises an error' do
        expect { Peribot.config }.to raise_error('No config directory defined')
      end
    end

    context 'with a conf_directory set' do
      let(:dir) do
        File.expand_path('./fixtures/config', File.dirname(__FILE__))
      end

      let(:file) do
        File.expand_path('./fixtures/config/test.conf', File.dirname(__FILE__))
      end

      let(:contents) { { 'number' => 1, 'string' => 'It works!' } }

      before(:each) do
        Peribot.configure { conf_directory dir }
      end

      it 'loads configuration files in the directory' do
        expect(File.exist?(file)).to be true
        expect(Peribot.config['test']).to eq(contents)
      end

      it 'freezes the config object' do
        expect(Peribot.config).to be_frozen
      end
    end
  end

  describe '.store' do
    let!(:dir) { Dir.mktmpdir }

    context 'before configuration' do
      before(:each) { Peribot.reset }

      it 'raises an error' do
        expect { Peribot.store('') }.to raise_error('Peribot is not configured')
      end
    end

    context 'with no store_directory set' do
      before(:each) { Peribot.configure {} }

      it 'raises an error' do
        msg = 'No store directory defined'
        expect { Peribot.store('') }.to raise_error(msg)
      end
    end

    context 'with a store_directory set' do
      before(:each) do
        Peribot.configure { store_directory dir }
      end

      it 'returns a Concurrent::Atom' do
        expect(Peribot.store('test')).to be_instance_of(Concurrent::Atom)
      end

      it 'returns the same Atom for a given key' do
        expect(Peribot.store('test')).to equal(Peribot.store('test'))
      end

      it 'creates a persistent store file when writing' do
        Peribot.store('test').swap { 'It works!' }

        file = File.join dir, 'test.store'
        expect(File.exist?(file)).to be true
      end
    end
  end

  describe '.reset' do
    it 'resets configuration for this instance' do
      Peribot.configure {}
      Peribot.reset

      expect { Peribot.config }.to raise_error('Peribot is not configured')
      expect { Peribot.store('') }.to raise_error('Peribot is not configured')
    end
  end
end
