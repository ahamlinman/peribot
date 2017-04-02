require 'spec_helper'

describe Peribot::Bot do
  let(:instance) { Peribot::Bot.new }
  let(:service) { Class.new(Peribot::Service) }
  let(:service_instance) { instance_double(Peribot::Service) }

  it 'allows preprocessor registration' do
    expect(instance.preprocessor).to respond_to(:register)
  end

  it 'allows postprocessor registration' do
    expect(instance.postprocessor).to respond_to(:register)
  end

  it 'allows sender registration' do
    expect(instance.sender).to respond_to(:register)
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

  describe '#caches' do
    it 'creates temporary Concurrent::Atom stores' do
      instance.caches['test'].swap { |o| o.merge('works' => true) }
      expect(instance.caches['test'].value).to eq('works' => true)
    end

    it 'allows array-style access' do
      instance.caches['test']['key'] = 'value'
      expect(instance.caches['test']['key']).to eq('value')
    end
  end

  describe '#accept' do
    def get_processor(phase)
      proc do |_, message, &acceptor|
        acceptor.call message.merge(
          count: message[:count] + 1,
          phase => message[:count]
        )
      end
    end

    it 'sends messages through each processing phase in order' do
      instance.preprocessor.register get_processor(:preprocessor)
      instance.register get_processor(:service)
      instance.postprocessor.register get_processor(:postprocessor)

      result = {}
      instance.sender.register(proc do |_, message|
        result = message.merge(sender: message[:count])
      end)

      instance.accept(count: 0)

      expect { result }.to eventually include(
        preprocessor: 0,
        service: 1,
        postprocessor: 2,
        sender: 3
      )
    end
  end
end
