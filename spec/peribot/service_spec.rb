require 'spec_helper'

describe Peribot::Service do
  let(:base) { Peribot::Service }
  let(:message) do
    { service: :msgr, group: 'msgr/1234', text: '#test this' }.freeze
  end
  let(:reply) do
    { service: :msgr, group: 'msgr/1234', text: 'Success!' }
  end
  let(:bot) { instance_double(Peribot::Bot) }
  let(:postprocessor) { instance_double(Peribot::ProcessorChain) }

  it 'supports message handlers in subclasses' do
    subclass = Class.new(base) do
      def test(**); end
      on_message :test
    end

    expect(subclass.message_handlers).to contain_exactly(:test)
  end

  it 'supports command handlers in subclasses' do
    subclass = Class.new(base) do
      def test(**); end
      on_command :cmd, :test
    end

    expect(subclass.command_handlers).to include('cmd' => :test)
  end

  it 'supports listen handlers in subclasses' do
    subclass = Class.new(base) do
      def test(**); end
      on_hear(/match/, :test)
    end

    expect(subclass.listen_handlers).to include(/match/ => :test)
  end

  it 'registers itself into bot instances properly' do
    subclass = Class.new(base)
    expect(bot).to receive(:register).with(subclass)
    subclass.register_into bot
  end

  it 'supports a call method' do
    subclass = Class.new(base) do
      def test_handler(message:, **)
        {
          service: message[:service],
          group: message[:group],
          text: 'Success!'
        }
      end
      on_message :test_handler
    end

    acceptor = double('acceptor')
    expect(acceptor).to receive(:call).with(hash_including(reply))

    subclass.call(bot, message, &acceptor.method(:call)).wait
  end

  describe '#accept' do
    it 'returns a promise' do
      subclass = Class.new(base)
      msg = { service: :msgr, group: 'msgr/1', text: 'test' }
      result = subclass.call(bot, msg) {}
      expect(result).to be_instance_of(Concurrent::Promise)
    end

    context 'with a message handler' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(message:)
            {
              service: message[:service],
              group: message[:group],
              text: 'Success!',
              original: message
            }
          end
          on_message :test_handler
        end
      end

      it 'replies to any message' do
        result = {}
        subclass.call(bot, message) { |output| result = output }.wait
        expect(result).to include(reply)
      end

      it 'passes the original message as an argument' do
        passed = false
        subclass.call(bot, message) { |o| passed = o.include?(:original) }.wait
        expect(passed).to be true
      end
    end

    context 'with a command handler' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(command:, arguments:, message:)
            {
              service: message[:service],
              group: message[:group],
              text: 'Success!',
              command: command,
              arguments: arguments
            }
          end
          on_command :test, :test_handler
          on_command :'my.cmd', :test_handler
        end
      end

      context 'with a regular command and an argument' do
        it 'replies to messages with the command' do
          result = {}
          subclass.call(bot, message) { |output| result = output }.wait
          expect(result).to include(reply)
        end

        it 'does not reply to messages without the command' do
          bad_msg = message.dup
          bad_msg[:text] = 'Do not process this!'

          subclass.call(bot, bad_msg) { raise 'Should not have output' }.wait
        end

        it 'passes the command to the handler as a string' do
          result = {}
          subclass.call(bot, message) { |output| result = output }.wait
          expect(result).to include(command: 'test')
        end

        it 'passes the argument to the handler' do
          result = {}
          subclass.call(bot, message) { |output| result = output }.wait
          expect(result).to include(arguments: 'this')
        end
      end

      context 'with commands containing special chars and no argument' do
        let(:message) do
          {
            service: :msgr,
            group: 'msgr/1234',
            text: '#my.cmd'
          }.freeze
        end

        it 'replies to messages with commands' do
          result = {}
          subclass.call(bot, message) { |output| result = output }.wait
          expect(result).to include(reply)
        end

        it 'does not reply to messages without commands' do
          bad_msg = message.dup
          bad_msg[:text] = 'Do not process this!'

          subclass.call(bot, bad_msg) { raise 'Should not have output' }.wait
        end

        it 'passes nil as the argument' do
          result = {}
          subclass.call(bot, message) { |output| result = output }.wait
          expect(result).to include(arguments: nil)
        end
      end

      context 'with an argument containing multiple words' do
        let(:message) do
          {
            service: :msgs,
            group: 'msgs/1',
            text: '#test me now'
          }.freeze
        end

        it 'passes the full argument to the handler' do
          result = {}
          subclass.call(bot, message) { |output| result = output }.wait
          expect(result).to include(arguments: 'me now')
        end
      end
    end

    context 'with multiple command handlers' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(**)
            'first test'
          end
          on_command :test, :test_handler

          def testing_handler(**)
            'second test'
          end
          on_command :testing, :testing_handler
        end
      end

      it 'does not reply when only part of a command matches' do
        message = { service: :msgs, group: 'msgs/1', text: '#testing' }
        count = 0
        subclass.call(bot, message) { |*| count += 1 }.wait

        expect(count).to eq(1)
      end

      it 'does not reply when only part of a command with argument matches' do
        message = { service: :msgs, group: 'msgs/1', text: '#testing now' }
        count = 0
        subclass.call(bot, message) { |*| count += 1 }.wait

        expect(count).to eq(1)
      end
    end

    context 'with a listen handler' do
      let(:subclass) do
        Class.new(base) do
          def listen_handler(message:, **)
            {
              service: message[:service],
              group: message[:group],
              text: 'Success!'
            }
          end
          on_hear(/this/, :listen_handler)
        end
      end

      it 'replies to messages matching a regex' do
        result = {}
        subclass.call(bot, message) { |output| result = output }.wait
        expect(result).to include(reply)
      end

      it 'does not reply to messages not matching the regex' do
        bad_msg = message.dup
        bad_msg[:text] = 'It will not match!'

        subclass.call(bot, bad_msg) { raise 'Should not have output' }.wait
      end
    end

    context 'with a handler using the bot instance' do
      let(:subclass) do
        Class.new(base) do
          def handler(**)
            bot.log 'test'
          end
          on_message :handler
        end
      end

      it 'allows bot use through an accessor' do
        expect(bot).to receive(:log).with('test')
        subclass.call(bot, message) {}.wait
      end
    end

    context 'with a handler returning nil' do
      let(:subclass) do
        Class.new(base) do
          def handler(*)
            nil
          end
          on_message :handler
        end
      end

      it 'does not send a reply' do
        subclass.call(bot, message) { raise 'Should not have output' }.wait
      end
    end

    context 'with a private handler' do
      let(:subclass) do
        Class.new(base) do
          private

          def handler(**)
            'Success!'
          end
          on_message :handler
        end
      end

      it 'calls the handler' do
        result = {}
        subclass.call(bot, message) { |output| result = output }.wait
        expect(result).to include(reply)
      end
    end

    context 'with a handler returning multiple messages' do
      let(:subclass) do
        Class.new(base) do
          def handler(**)
            ['Success!', { service: :x, group: 'x/1', text: 'x' }]
          end
          on_message :handler
        end
      end

      it 'sends multiple replies' do
        results = []
        subclass.call(bot, message) { |output| results << output }.wait

        expect(results).to include(reply)
        expect(results).to include(service: :x, group: 'x/1', text: 'x')
      end
    end

    context 'with a handler that raises an error' do
      let(:subclass) do
        Class.new(base) do
          def failing_handler(**)
            raise 'This is just part of the test.'
          end
          on_message :failing_handler

          def succeeding_handler(**)
            'Success!'
          end
          on_message :succeeding_handler
        end
      end

      it 'sends one message and logs an error' do
        expect(bot).to receive(:log) do |msg|
          raise unless msg =~ /exception =/ # make sure exception is logged
          raise unless msg =~ /message =/   # make sure message is logged
          raise unless msg =~ /#test this/  # make sure message text is there
        end

        result = {}
        subclass.call(bot, message) { |output| result = output }.wait
        expect(result).to include(reply)
      end
    end

    context 'with a message handler registered multiple times' do
      let(:subclass) do
        Class.new(base) do
          def message(**)
            'Message!'
          end
          on_message :message
          on_message :message
        end
      end

      it 'only calls message handlers once' do
        message = { service: :x, group: 'x/1', text: 'message' }
        count = 0
        subclass.call(bot, message) { |*| count += 1 }.wait
        expect(count).to eq(1)
      end
    end

    context 'with a command handler registered multiple times' do
      let(:subclass) do
        Class.new(base) do
          def command(**)
            'Command!'
          end
          on_command :test, :command
          on_command :test, :command
        end
      end

      it 'only calls command handlers once' do
        message = { service: :x, group: 'x/1', text: '#test' }
        count = 0
        subclass.call(bot, message) { |*| count += 1 }.wait
        expect(count).to eq(1)
      end
    end

    context 'with a listen handler registered multiple times' do
      let(:subclass) do
        Class.new(base) do
          def listen(match:, **)
            match[1]
          end
          on_hear(/bad handler/, :listen)
          on_hear(/(simple) test/, :listen)
          on_hear(/simple (test)/, :listen)
        end
      end

      let(:message) do
        { service: :x, group: 'x/1', text: 'simple test' }
      end
      let(:reply) do
        { service: :x, group: 'x/1', text: 'simple' }
      end

      it 'only calls the handler once' do
        count = 0
        subclass.call(bot, message) { |*| count += 1 }.wait
        expect(count).to eq(1)
      end

      it 'calls the handler with data for the first matching regex' do
        result = {}
        subclass.call(bot, message) { |output| result = output }.wait
        expect(result).to include(reply)
      end
    end

    shared_context 'invalid message' do
      let(:subclass) { Class.new(base) }
      let(:err) do
        'invalid message (must have text, service, and group)'
      end

      it 'fails to process the message' do
        expect { subclass.call(bot, message) {}.wait }.to raise_error(err)
      end
    end

    context 'with an empty message' do
      let(:message) { {} }
      include_context 'invalid message'
    end

    context 'with a message missing a group' do
      let(:message) { { service: :x, text: 'This is a test message.' } }
      include_context 'invalid message'
    end

    context 'with a message with a nil group' do
      let(:message) { { service: :x, group: nil, text: 'Test' } }
      include_context 'invalid message'
    end

    context 'with a message missing text' do
      let(:message) { { service: :x, group: 'x/1234' } }
      include_context 'invalid message'
    end

    context 'with a message with nil text' do
      let(:message) { { service: :x, group: 'x/1234', text: nil } }
      include_context 'invalid message'
    end

    context 'with a message missing a service' do
      let(:message) { { group: 'x/1234', text: 'Test' } }
      include_context 'invalid message'
    end

    context 'with a message with a nil service' do
      let(:message) { { service: nil, group: 'x/1234', text: 'Test' } }
      include_context 'invalid message'
    end
  end
end
