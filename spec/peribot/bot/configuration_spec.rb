require 'spec_helper'

describe Peribot::Bot::Configuration do
  let(:test_class) do
    Class.new do
      include Peribot::Bot::Configuration
      def setup(conf_dir)
        setup_config_directory conf_dir
        self
      end
    end
  end

  let(:dir) { File.expand_path('../../../fixtures/config', __FILE__) }
  let(:file) { File.join(dir, 'test.conf') }
  let(:contents) { { 'number' => 1, 'string' => 'It works!' } }

  context 'with no config directory set up' do
    let(:instance) { test_class.new }

    it 'raises an error when retrieving configuration' do
      expect { instance.config }.to raise_error('No config directory defined')
    end
  end

  context 'when setting up a nil config directory' do
    let(:instance) { test_class.new.setup nil }

    it 'raises an error upon setup' do
      expect { instance }.to raise_error('No config directory defined')
    end
  end

  context 'with a config directory given' do
    let(:instance) { test_class.new.setup dir }

    it 'loads configuration files in the directory' do
      expect(File.exist?(file)).to be true
      expect(instance.config['test']).to eq(contents)
    end

    it 'freezes the config object' do
      expect(instance.config).to be_frozen
    end
  end
end
