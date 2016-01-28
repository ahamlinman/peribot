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

  # This ensures that any processor chains created by the bot are actually
  # initialized with the bot itself (which is pretty much the whole idea of
  # initializing those chains with a bot).
  before(:each) do
    allow(Peribot::ProcessorChain).to receive(:new)
      .with(instance_of(Peribot::Bot)).and_call_original
  end

  it 'has a preprocessor' do
    expect(instance.preprocessor).to respond_to(:accept)
  end

  it 'has a postprocessor' do
    expect(instance.postprocessor).to respond_to(:accept)
  end

  it 'has a sender' do
    expect(instance.sender).to respond_to(:accept)
  end

  describe '#accept' do
    it 'sends messages to the preprocessor' do
      expect(instance.preprocessor).to receive(:accept).with({})
      instance.accept({})
    end
  end

  describe '#register' do
    let(:service) { Class.new(Peribot::Service) }

    it 'adds a service to the service list' do
      instance.register service
      expect(instance.services).to include(service)
    end

    it 'does not add services more than once' do
      instance.register service
      instance.register service

      expect(instance.services.count(service)).to eq(1)
    end
  end

  describe '#log' do
    it 'logs messages to stderr with a prefix' do
      expect { instance.log 'stuff' }.to output("[Peribot] stuff\n").to_stderr
    end
  end

  describe '#cache' do
    it 'creates temporary Concurrent::Atom stores' do
      instance.cache['test'].swap { |o| o.merge('works' => true) }
      expect(instance.cache['test'].value).to eq('works' => true)
    end
  end

  describe '#preprocessor' do
    let(:service) do
      Class.new(Peribot::Service) do
        def handle(message)
          puts message.inspect
          puts message.frozen?
        end
        on_message :handle
      end
    end

    let(:result) { instance.preprocessor.accept({}).value.each(&:wait) }

    it 'forwards frozen messages to services after processing' do
      instance.register service
      expect { result }.to output("{}\ntrue\n").to_stdout
    end
  end

  describe '#postprocessor' do
    it 'forwards messages to senders after postprocessing' do
      expect(instance.sender).to receive(:accept).with({})
      instance.postprocessor.accept({}).wait
    end
  end

  describe '#sender' do
    let(:test_sender) do
      Class.new(Peribot::Processor) do
        def process(message)
          puts message.inspect
        end
      end
    end

    it 'can register senders and give them messages' do
      instance.sender.register test_sender
      expect { instance.sender.accept({}).wait }.to output("{}\n").to_stdout
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
