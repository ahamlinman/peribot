require 'spec_helper'

describe Peribot::Service do
  it 'supports message handlers in subclasses' do
    subclass = Class.new(Peribot::Service) do
      def test(*); end
      on_message :test
    end

    expect(subclass.message_handlers).to contain_exactly(:test)
  end

  it 'supports command handlers in subclasses' do
    subclass = Class.new(Peribot::Service) do
      def test(*); end
      on_command :cmd, :test
    end

    expect(subclass.command_handlers).to include('cmd' => :test)
  end

  it 'supports listen handlers in subclasses' do
    subclass = Class.new(Peribot::Service) do
      def test(*); end
      on_hear(/match/, :test)
    end

    expect(subclass.listen_handlers).to include(/match/ => :test)
  end

  describe '#accept' do
    let(:base) { Peribot::Service }
    let(:message) { { 'group_id' => '1234', 'text' => '#test this' }.freeze }
    let(:reply) { { 'group_id' => '1234', 'text' => 'Success!' } }
    let(:bot) { instance_double(Peribot::Bot) }
    let(:postprocessor) { instance_double(Peribot::ProcessorChain) }

    it 'returns a promise' do
      subclass = Class.new(base)
      instance = subclass.new bot, postprocessor
      expect(instance.accept({})).to be_instance_of(Concurrent::Promise)
    end

    context 'with a message handler' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(*)
            'Success!'
          end
          on_message :test_handler
        end
      end

      it 'replies to any message' do
        expect(postprocessor).to receive(:accept).with(reply)

        instance = subclass.new bot, postprocessor
        instance.accept(message).value
      end
    end

    context 'with a command handler' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(_command, _arguments, message)
            { 'group_id' => message['group_id'], 'text' => 'Success!' }
          end
          on_command :test, :test_handler
          on_command :'my.cmd', :test_handler
        end
      end

      context 'with commands not containing special chars' do
        it 'replies to messages with commands' do
          expect(postprocessor).to receive(:accept).with(reply)

          instance = subclass.new bot, postprocessor
          instance.accept(message).value
        end

        it 'does not reply to messages without commands' do
          expect(postprocessor).to_not receive(:accept)

          bad_msg = message.dup
          bad_msg['text'] = 'Do not process this!'

          instance = subclass.new bot, postprocessor
          instance.accept(bad_msg).value
        end
      end

      context 'with commands containing special chars' do
        let(:message) { { 'group_id' => '1234', 'text' => '#my.cmd' }.freeze }

        it 'replies to messages with commands' do
          expect(postprocessor).to receive(:accept).with(reply)

          instance = subclass.new bot, postprocessor
          instance.accept(message).value
        end

        it 'does not reply to messages without commands' do
          expect(postprocessor).to_not receive(:accept)

          bad_msg = message.dup
          bad_msg['text'] = '#my cmd'

          instance = subclass.new bot, postprocessor
          instance.accept(bad_msg).value
        end
      end
    end

    context 'with multiple command handlers' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(*)
            'first test'
          end
          on_command :test, :test_handler

          def testing_handler(*)
            'second test'
          end
          on_command :testing, :testing_handler
        end
      end

      it 'does not reply when only part of a command matches' do
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept('group_id' => '1', 'text' => '#testing').value
      end

      it 'does not reply when only part of a command with argument matches' do
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept('group_id' => '1', 'text' => '#testing now').value
      end
    end

    context 'with a listen handler' do
      let(:subclass) do
        Class.new(base) do
          def listen_handler(_match, message)
            { 'group_id' => message['group_id'], 'text' => 'Success!' }
          end
          on_hear(/this/, :listen_handler)
        end
      end

      it 'replies to messages matching a regex' do
        expect(postprocessor).to receive(:accept).with(reply)

        instance = subclass.new bot, postprocessor
        instance.accept(message).value
      end

      it 'does not reply to messages not matching the regex' do
        expect(postprocessor).to_not receive(:accept)

        bad_msg = message.dup
        bad_msg['text'] = 'It will not match!'

        instance = subclass.new bot, postprocessor
        instance.accept(bad_msg).value
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
        instance.accept(message).value
      end
    end

    context 'with a handler returning multiple messages' do
      let(:subclass) do
        Class.new(base) do
          def handler(*)
            ['Success!', { 'another' => 'reply' }]
          end
          on_message :handler
        end
      end

      it 'sends multiple replies' do
        expect(postprocessor).to receive(:accept).with(reply)
        expect(postprocessor).to receive(:accept).with('another' => 'reply')

        instance = subclass.new bot, postprocessor
        instance.accept(message).value
      end
    end

    context 'with a handler that raises an error' do
      let(:subclass) do
        Class.new(base) do
          def failing_handler(*)
            fail 'This is just part of the test.'
          end
          on_message :failing_handler

          def succeeding_handler(*)
            'Success!'
          end
          on_message :succeeding_handler
        end
      end

      it 'sends one message and logs an error' do
        expect(postprocessor).to receive(:accept).with(reply)
        expect(bot).to receive(:log)

        instance = subclass.new bot, postprocessor
        instance.accept(message).value
      end
    end

    context 'with a message handler registered multiple times' do
      let(:subclass) do
        Class.new(base) do
          def message(*)
            'Message!'
          end
          on_message :message
          on_message :message
        end
      end

      it 'only calls message handlers once' do
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept('group_id' => '1', 'text' => 'message').value
      end
    end

    context 'with a command handler registered multiple times' do
      let(:subclass) do
        Class.new(base) do
          def command(*)
            'Command!'
          end
          on_command :test, :command
          on_command :test, :command
        end
      end

      it 'only calls command handlers once' do
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept('group_id' => '1', 'text' => '#test').value
      end
    end

    context 'with a listen handler registered multiple times' do
      let(:subclass) do
        Class.new(base) do
          def listen(match, _)
            match[1]
          end
          on_hear(/(simple) test/, :listen)
          on_hear(/simple (test)/, :listen)
        end
      end
      let(:message) { { 'group_id' => '1', 'text' => 'simple test' } }
      let(:reply) { { 'group_id' => '1', 'text' => 'simple' } }

      it 'only calls the handler once' do
        expect(postprocessor).to receive(:accept).once

        instance = subclass.new bot, postprocessor
        instance.accept(message).value
      end

      it 'calls the handler with data for the first regex' do
        expect(postprocessor).to receive(:accept).with(reply)

        instance = subclass.new bot, postprocessor
        instance.accept(message).value
      end
    end
  end
end
