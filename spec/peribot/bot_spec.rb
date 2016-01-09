require 'spec_helper'

describe Peribot::Bot do
  let(:instance) { Peribot::Bot.new(config_directory: '', store_directory: '') }

  let(:task) do
    Class.new(Peribot::Middleware::Task) do
      def process(message)
        puts message.inspect
      end
    end
  end

  let(:service) do
    Class.new(Peribot::Service) do
      def handle(*)
        { 'group_id' => '0', 'text' => 'Reply' }
      end
      on_message :handle
    end
  end

  it 'has a preprocessor chain' do
    expect(instance.preprocessor).to be_instance_of(Peribot::Middleware::Chain)
  end

  it 'has a postprocessor chain' do
    expect(instance.postprocessor).to be_instance_of(Peribot::Middleware::Chain)
  end

  it 'has a sender chain' do
    expect(instance.sender).to be_instance_of(Peribot::Middleware::Chain)
  end

  describe '#register' do
    let(:service) { Class.new(Peribot::Service) }

    it 'adds a service to the service list' do
      instance.register service
      expect(instance.services).to include(service)
    end
  end

  describe '#log' do
    it 'logs messages to stderr with a prefix' do
      expect { instance.log 'stuff' }.to output("[Peribot] stuff\n").to_stderr
    end
  end

  describe '#preprocessor' do
    let(:service) do
      Class.new(Peribot::Service) do
        def handle(message)
          puts message.inspect
        end
        on_message :handle
      end
    end

    let(:result) { instance.preprocessor.accept({}).value.each(&:value) }

    it 'forwards messages to services after processing' do
      instance.register service
      expect { result }.to output("{}\n").to_stdout
    end
  end

  describe '#postprocessor' do
    it 'forwards messages to senders after postprocessing' do
      expect(instance.sender).to receive(:accept).with({})
      instance.postprocessor.accept({}).value
    end
  end

  context 'without a config_directory parameter' do
    let(:instance) { Peribot::Bot.new(store_directory: '') }

    it 'raises an error when instantiated' do
      expect { instance }.to raise_error('No config directory defined')
    end
  end

  context 'without a store_directory parameter' do
    let(:instance) { Peribot::Bot.new(config_directory: '') }

    it 'raises an error when instantiated' do
      expect { instance }.to raise_error('No store directory defined')
    end
  end
end
