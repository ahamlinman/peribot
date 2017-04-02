require 'spec_helper'

describe Peribot::Processor do
  let(:bot) { instance_double(Peribot::Bot) }
  let(:task) { Peribot::Processor.new bot }

  it 'defines a default register_into that gives an error' do
    task = Class.new(Peribot::Processor)
    bot = instance_double(Peribot::Bot)

    expect { task.register_into bot }.to raise_error(NotImplementedError)
  end

  it 'provides access to the bot it was initialized with' do
    task = Class.new(Peribot::Processor) do
      def process(*)
        bot.log 'test'
      end
    end

    expect(bot).to receive(:log).with('test')
    task.new(bot).process({})
  end

  describe '.call' do
    it 'runs the processor' do
      task = Class.new(Peribot::Processor) do
        def process(message)
          bot.log 'test'
          message
        end
      end

      expect(bot).to receive(:log).with('test')

      acceptor = double('acceptor')
      expect(acceptor).to receive(:call).with(message: 'hi')

      task.call(bot, { message: 'hi' }, &acceptor.method(:call)).wait
    end

    it 'normalizes and handles advanced return formats' do
      message = { service: :x, group: 'x/1' }
      task = Class.new(Peribot::Processor) do
        def process(_)
          [nil, 'It works!']
        end
      end

      acceptor = double('acceptor')
      expect(acceptor).to receive(:call).with(service: :x, group: 'x/1',
                                              text: 'It works!')

      task.call(bot, message.merge(text: 'hi'), &acceptor.method(:call)).wait
    end

    it 'logs processor failures' do
      task = Class.new(Peribot::Processor) do
        def process(*)
          raise 'sample error'
        end
      end

      expect(bot).to receive(:log).with(/Error in/)
      task.call(bot, {}) { raise 'Should not have output' }.wait
    end
  end

  describe '#process' do
    it 'fails when not implemented' do
      msg = 'process method not implemented in Peribot::Processor'
      expect { task.process({}) }.to raise_error(msg)
    end
  end
end
