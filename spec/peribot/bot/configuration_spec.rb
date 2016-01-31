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
  let(:empty_dir) { File.expand_path('../../../fixtures/empty', __FILE__) }
  let(:error_dir) { File.expand_path('../../../fixtures/error', __FILE__) }
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
      expect(instance.config).to include('other')
    end

    it 'freezes the config object' do
      expect(instance.config).to be_frozen
    end
  end

  context 'with a config directory containing no files' do
    let(:instance) { test_class.new.setup empty_dir }

    it 'returns an empty hash' do
      expect(instance.config).to eq({})
    end
  end

  context 'with a directory containing invalid files' do
    let(:instance) { test_class.new.setup error_dir }

    it 'raises a syntax error during parsing' do
      expect { instance.config }.to raise_error(Psych::SyntaxError)
    end
  end
end
