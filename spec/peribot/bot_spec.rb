require 'spec_helper'

describe Peribot::Bot do
  let(:instance) { Peribot::Bot.new }

  let(:task) do
    Class.new(Peribot::Middleware::Task) do
      def process(message)
        puts message.inspect
      end
    end
  end

  let(:service) { Class.new(Peribot::Service) }
  let(:service_instance) { instance_double(Peribot::Service) }

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

  it 'initializes services with itself and the postprocessor' do
    instance.register service

    expect(service).to receive(:new)
      .with(instance_of(Peribot::Bot), instance_of(Peribot::ProcessorChain))
      .and_return(service_instance)
    allow(service_instance).to receive(:accept)

    instance.accept({}).wait
  end

  context 'with an explicit store_file parameter' do
    let(:instance) { Peribot::Bot.new(store_file: '') }

    it 'sets the store file' do
      expect(instance.store_file).to eq('')
    end
  end

  describe '#config' do
    before(:all) do
      @filename = File.expand_path('../fixtures/config.yml', __dir__)
    end

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

      context 'with no environment configuration' do
        before(:all) do
          @cwd = Dir.pwd
          Dir.chdir(File.expand_path('../fixtures', __dir__))
        end
        after(:all) { Dir.chdir @cwd }
        include_context 'loads configuration'
      end
    end

    context 'with a bad configuration file' do
      before(:all) do
        @filename = File.expand_path('../fixtures/bad_config.yml', __dir__)
      end
      let(:instance) { Peribot::Bot.new(config_file: @filename) }

      it 'raises an error' do
        expect { instance }.to raise_error(Psych::Exception)
      end
    end
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

  describe '#use' do
    let(:collection) { double('service collection') }

    it 'makes a collection register without arguments' do
      expect(collection).to receive(:register_into).with(instance)
      instance.use collection
    end

    it 'makes a collection register with arguments' do
      expect(collection).to receive(:register_into).with(instance, 1, kw: 'yes')
      instance.use collection, 1, kw: 'yes'
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

    it 'allows array-style access' do
      instance.cache['test']['key'] = 'value'
      expect(instance.cache['test']['key']).to eq('value')
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

    let(:msg) { { 'group_id' => '1', 'text' => 'test' } }
    let(:result) { instance.preprocessor.accept(msg).value.each(&:wait) }

    it 'forwards frozen messages to services after processing' do
      instance.register service
      expect { result }.to output("#{msg}\ntrue\n").to_stdout
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
end
