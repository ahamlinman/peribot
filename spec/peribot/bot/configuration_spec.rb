require 'spec_helper'

describe Peribot::Bot::Configuration do
  let(:test_class) do
    Class.new do
      include Peribot::Bot::Configuration
      def initialize(filename = nil)
        @config_file = filename
      end
    end
  end

  before(:all) do
    @filename = File.expand_path('../../fixtures/config.yml', __dir__)
  end

  let(:instance) { test_class.new @filename }

  shared_context 'loads configuration' do
    it 'loads the proper configuration' do
      expect(instance.config).to eq('number' => 1, 'string' => 'hi')
    end
  end

  context 'with an explicit configuration file' do
    let(:instance) { Peribot::Bot.new(config_file: @filename) }
    include_context 'loads configuration'
  end

  context 'with no explicit configuration file' do
    context 'with configuration from the environment' do
      before(:all) { ENV['PERIBOT_CONFIG'] = @filename }
      after(:all) { ENV['PERIBOT_CONFIG'] = nil }
      include_context 'loads configuration'
    end

    context 'with a default file' do
      before(:all) do
        @cwd = Dir.pwd
        Dir.chdir(File.expand_path('../../fixtures', __dir__))
      end
      after(:all) { Dir.chdir @cwd }
      include_context 'loads configuration'
    end

    context 'with no default file' do
      before(:all) do
        @cwd = Dir.pwd
        Dir.chdir(File.expand_path('../../fixtures/empty', __dir__))
      end
      after(:all) { Dir.chdir @cwd }
      let(:instance) { test_class.new }

      it 'raises an error' do
        expect { instance.config }.to raise_error(
          'Could not find configuration')
      end
    end
  end

  context 'with a bad configuration file' do
    before(:all) do
      @filename = File.expand_path('../../fixtures/bad_config.yml', __dir__)
    end
    let(:instance) { test_class.new @filename }

    it 'raises an error' do
      expect { instance.config }.to raise_error(Psych::Exception)
    end
  end
end
