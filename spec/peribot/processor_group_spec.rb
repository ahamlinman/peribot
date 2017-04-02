require 'spec_helper'

describe Peribot::ProcessorGroup do
  let(:bot) { instance_double(Peribot::Bot) }

  describe '#accept' do
    context 'with one task' do
      it 'executes the task' do
        task = proc do |_, message|
          puts message.inspect
        end

        instance = described_class.new([task])
        expect { instance.call(bot, {}) {} }.to output("{}\n").to_stdout
      end
    end

    context 'with a task using the bot instance' do
      it 'provides proper access to the bot' do
        task = proc do |bot, _|
          bot.log 'test'
        end

        instance = described_class.new([task])

        expect(bot).to receive(:log).with('test')
        instance.call(bot, {}) {}
      end
    end

    context 'with a task raising an error' do
      let(:message) { { test: true } }

      it 'outputs a log via the bot' do
        task = proc { |*| raise 'just testing' }

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
        instance.call(bot, message) {}
      end
    end
  end
end
