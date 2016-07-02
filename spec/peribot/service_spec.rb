require 'spec_helper'

describe Peribot::Service do
  it 'supports message handlers in subclasses' do
    subclass = Class.new(Peribot::Service) do
      def test(**); end
      on_message :test
    end

    expect(subclass.message_handlers).to contain_exactly(:test)
  end

  it 'supports command handlers in subclasses' do
    subclass = Class.new(Peribot::Service) do
      def test(**); end
      on_command :cmd, :test
    end

    expect(subclass.command_handlers).to include('cmd' => :test)
  end

  it 'supports listen handlers in subclasses' do
    subclass = Class.new(Peribot::Service) do
      def test(**); end
      on_hear(/match/, :test)
    end

    expect(subclass.listen_handlers).to include(/match/ => :test)
  end

  it 'registers itself into bot instances properly' do
    subclass = Class.new(Peribot::Service)
    bot = instance_double(Peribot::Bot)

    expect(bot).to receive(:register).with(subclass)
    subclass.register_into bot
  end

  describe '#accept' do
    let(:base) { Peribot::Service }
    let(:message) do
      {
        service: :msgr,
        group: 'msgr/1234',
        text: '#test this'
      }.freeze
    end
    let(:reply) do
      { service: :msgr, group: 'msgr/1234', text: 'Success!' }
    end
    let(:bot) { instance_double(Peribot::Bot) }
    let(:postprocessor) { instance_double(Peribot::ProcessorChain) }

    it 'returns a promise' do
      subclass = Class.new(base)
      instance = subclass.new bot, postprocessor
      msg = { service: :msgr, group: 'msgr/1', text: 'test' }
      expect(instance.accept(msg)).to be_instance_of(Concurrent::Promise)
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
        expect(postprocessor).to receive(:accept).with(hash_including(reply))

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
      end

      it 'passes the original message as an argument' do
        expect(postprocessor).to receive(:accept)
          .with(hash_including(original: message))

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
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
          expect(postprocessor).to receive(:accept).with(hash_including(reply))

          instance = subclass.new bot, postprocessor
          instance.accept(message).wait
        end

        it 'does not reply to messages without the command' do
          expect(postprocessor).to_not receive(:accept)

          bad_msg = message.dup
          bad_msg[:text] = 'Do not process this!'

          instance = subclass.new bot, postprocessor
          instance.accept(bad_msg).wait
        end

        it 'passes the argument to the handler' do
          expect(postprocessor).to receive(:accept)
            .with(hash_including(arguments: 'this'))

          instance = subclass.new bot, postprocessor
          instance.accept(message).wait
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
          expect(postprocessor).to receive(:accept).with(hash_including(reply))

          instance = subclass.new bot, postprocessor
          instance.accept(message).wait
        end

        it 'does not reply to messages without commands' do
          expect(postprocessor).to_not receive(:accept)

          bad_msg = message.dup
          bad_msg[:text] = '#my cmd'

          instance = subclass.new bot, postprocessor
          instance.accept(bad_msg).wait
        end

        it 'passes nil as the argument' do
          expect(postprocessor).to receive(:accept)
            .with(hash_including(arguments: nil))

          instance = subclass.new bot, postprocessor
          instance.accept(message).wait
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
          expect(postprocessor).to receive(:accept)
            .with(hash_including(arguments: 'me now'))

          instance = subclass.new bot, postprocessor
          instance.accept(message).wait
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
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept(service: :msgs, group: 'msgs/1', text: '#testing').wait
      end

      it 'does not reply when only part of a command with argument matches' do
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept(service: :msgs, group: 'msgs/1',
                        text: '#testing now').wait
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
        expect(postprocessor).to receive(:accept).with(reply)

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
      end

      it 'does not reply to messages not matching the regex' do
        expect(postprocessor).to_not receive(:accept)

        bad_msg = message.dup
        bad_msg[:text] = 'It will not match!'

        instance = subclass.new bot, postprocessor
        instance.accept(bad_msg).wait
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

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
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
        expect(postprocessor).to_not receive(:accept)

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
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
        expect(postprocessor).to receive(:accept).with(reply)

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
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
        expect(postprocessor).to receive(:accept).with(reply)
        expect(postprocessor).to receive(:accept).with(service: :x,
                                                       group: 'x/1',
                                                       text: 'x')

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
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
        expect(postprocessor).to receive(:accept).with(reply)
        expect(bot).to receive(:log) do |msg|
          raise unless msg =~ /exception =/ # make sure exception is logged
          raise unless msg =~ /message =/   # make sure message is logged
          raise unless msg =~ /#test this/  # make sure message text is there
        end

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
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
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept(service: :x, group: 'x/1', text: 'message').wait
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
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept(service: :x, group: 'x/1', text: '#test').wait
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
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
      end

      it 'calls the handler with data for the first matching regex' do
        expect(postprocessor).to receive(:accept).with(reply)

        instance = subclass.new bot, postprocessor
        instance.accept(message).wait
      end
    end

    shared_context 'invalid message' do
      let(:subclass) { Class.new(base) }
      let(:error_message) do
        'invalid message (must have text, service, and group)'
      end

      it 'fails to process the message' do
        instance = subclass.new bot, postprocessor
        expect { instance.accept(message).wait }.to raise_error(error_message)
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
