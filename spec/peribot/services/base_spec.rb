require 'spec_helper'

describe Peribot::Services::Base do
  after(:each) do
    Peribot::Services.list.clear
  end

  it 'adds subclasses to the global service list' do
    subclass = Class.new(Peribot::Services::Base)
    expect(Peribot::Services.list).to include(subclass)
  end

  it 'supports message handlers in subclasses' do
    subclass = Class.new(Peribot::Services::Base) do
      def test(*); end
      on_message :test
    end

    expect(subclass.message_handlers).to contain_exactly(:test)
  end

  it 'supports command handlers in subclasses' do
    subclass = Class.new(Peribot::Services::Base) do
      def test(*); end
      on_command :cmd, :test
    end

    expect(subclass.command_handlers).to include('cmd' => :test)
  end

  it 'supports listen handlers in subclasses' do
    subclass = Class.new(Peribot::Services::Base) do
      def test(*); end
      on_hear(/match/, :test)
    end

    expect(subclass.listen_handlers).to include(/match/ => :test)
  end

  describe '#accept' do
    let(:base) { Peribot::Services::Base }
    let(:message) { { 'group_id' => '1234', 'text' => '#test this' }.freeze }
    let(:reply) { { 'group_id' => '1234', 'text' => 'Success!' } }
    let(:postprocessor) { Peribot::Postprocessor.instance }

    it 'returns a promise' do
      subclass = Class.new(base)
      expect(subclass.new.accept({})).to be_instance_of(Concurrent::Promise)
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
        subclass.new.accept(message).value
      end
    end

    context 'with a command handler' do
      let(:subclass) do
        Class.new(base) do
          def test_handler(_command, _arguments, message)
            { 'group_id' => message['group_id'], 'text' => 'Success!' }
          end
          on_command :test, :test_handler
        end
      end

      it 'replies to messages with commands' do
        expect(postprocessor).to receive(:accept).with(reply)
        subclass.new.accept(message).value
      end

      it 'does not reply to messages without commands' do
        expect(postprocessor).to_not receive(:accept)

        bad_msg = message.dup
        bad_msg['text'] = 'Do not process this!'
        subclass.new.accept(bad_msg).value
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
        subclass.new.accept(message).value
      end

      it 'does not reply to messages not matching the regex' do
        expect(postprocessor).to_not receive(:accept)

        bad_msg = message.dup
        bad_msg['text'] = 'It will not match!'
        subclass.new.accept(bad_msg).value
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
        subclass.new.accept(message).value
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
        subclass.new.accept(message).value
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

      it 'allows other handlers to work' do
        # Silencing stderr only for this test
        original_stderr = $stderr
        $stderr = File.open(File::NULL, 'w')

        expect(postprocessor).to receive(:accept).with(reply)
        subclass.new.accept(message).value

        $stderr = original_stderr
      end

      it 'logs the error to stderr' do
        expect { subclass.new.accept(message).value }.to output.to_stderr
      end
    end
  end
end
