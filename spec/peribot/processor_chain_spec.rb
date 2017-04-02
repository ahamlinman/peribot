require 'spec_helper'
require 'concurrent'

describe Peribot::ProcessorChain do
  let(:bot) { instance_double(Peribot::Bot) }

  describe '#call' do
    context 'with one task' do
      it 'executes the task' do
        task = proc do |_, message|
          puts message.inspect
        end

        instance = described_class.new([task])
        expect { instance.call(bot, {}) {}.wait }.to output("{}\n").to_stdout
      end
    end

    context 'with multiple tasks' do
      def task(count)
        proc do |_, message, &acceptor|
          acceptor.call(done: message[:done] + [count])
        end
      end

      it 'executes all of the tasks in order' do
        out = Concurrent::IVar.new
        instance = described_class.new([task(1), task(2), task(3)])
        instance.call(bot, done: []) { |res| out.set res[:done] }

        # Note that the call to #value blocks on the IVar being set
        expect(out.value).to eq [1, 2, 3]
      end
    end

    context 'with tasks returning multiple messages' do
      it 'forks to process all messages' do
        task = proc do |*, &acceptor|
          acceptor.call({})
          acceptor.call({})
        end

        instance = described_class.new([task, task, task])
        expected_outputs = 8

        count = Concurrent::AtomicFixnum.new
        latch = Concurrent::CountDownLatch.new expected_outputs
        instance.call(bot, {}) do |*|
          count.increment
          latch.count_down
        end
        latch.wait

        expect(count.value).to eq(expected_outputs)
      end
    end

    context 'with tasks using the bot instance' do
      it 'provides proper access to the bot' do
        task = proc do |bot, msg, &acceptor|
          bot.log 'test'
          acceptor.call msg
        end

        expect(bot).to receive(:log).with('test').twice

        done = Concurrent::Event.new
        instance = described_class.new([task, task])
        instance.call(bot, {}) { |*| done.set }
        done.wait
      end
    end

    context 'with a task raising an error' do
      let(:message) { { test: true } }

      it 'outputs a log via the bot' do
        task = proc do |*|
          raise 'just testing'
        end

        # Only part of the log will be matched. We just want to ensure that the
        # right message gets output and that the exception isn't forgotten.
        log_msg = <<-END
          => message = #{message}
          => exception =
        END
        log_msg.gsub!(/^\s{#{log_msg.match('\s+').to_s.length - 2}}/, '')
        log_msg.strip!

        expect(bot).to receive(:log).with(/#{Regexp.quote(log_msg)}/)
        instance = described_class.new([task])
        instance.call(bot, message) {}.wait
      end
    end
  end
end
