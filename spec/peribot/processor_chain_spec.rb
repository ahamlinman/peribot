require 'spec_helper'

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
        done = []
        instance = described_class.new([task(1), task(2), task(3)])
        instance.call(bot, done: []) { |out| done = out[:done] }

        expect { done }.to eventually(eq [1, 2, 3])
      end
    end

    context 'with tasks returning multiple messages' do
      it 'forks to process all messages' do
        count = 0
        task = proc do |*, &acceptor|
          count += 1
          acceptor.call({})
          acceptor.call({})
        end

        instance = described_class.new([task, task, task])
        instance.call(bot, {}) {}

        # 2^n - 1 increments expected from our "task tree"
        expect { count }.to eventually(eq 7)
      end
    end

    context 'with tasks using the bot instance' do
      it 'provides proper access to the bot' do
        task = proc do |bot, msg, &acceptor|
          bot.log 'test'
          acceptor.call msg
        end

        instance = described_class.new([task, task])
        expect(bot).to receive(:log).with('test').twice

        t = Thread.current
        instance.call(bot, {}) { |*| t.run }
        Thread.stop
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
