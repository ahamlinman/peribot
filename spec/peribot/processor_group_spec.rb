require 'spec_helper'

describe Peribot::ProcessorGroup do
  let(:bot) { instance_double(Peribot::Bot) }
  let(:instance) { Peribot::ProcessorGroup.new bot }

  it 'contains an accessible list of tasks' do
    expect(instance).to respond_to(:tasks)
  end

  describe '#register' do
    let(:task) { Class.new(Peribot::Processor) }

    it 'adds a task to the task list' do
      instance.register task

      expect(instance.tasks).to include(task)
    end

    it 'does not add tasks more than once' do
      instance.register task
      instance.register task

      expect(instance.tasks.count(task)).to eq(1)
    end
  end

  describe '#accept' do
    it 'returns an array of Concurrent::IVars' do
      promises = instance.accept('test' => true)
      result = promises.all? { |p| p.is_a? Concurrent::IVar }
      expect(result).to be true
    end

    context 'with one task' do
      it 'executes the task' do
        task = Class.new(Peribot::Processor) do
          def process(msg)
            puts msg.inspect
          end
        end
        instance.register task

        expect { instance.accept({}).each(&:wait) }.to output("{}\n").to_stdout
      end
    end

    context 'with a task using the bot instance' do
      it 'provides proper access to the bot' do
        task = Class.new(Peribot::Processor) do
          def process(*)
            bot.log 'test'
          end
        end
        instance.register task

        expect(bot).to receive(:log).with('test')
        instance.accept({}).each(&:wait)
      end
    end

    context 'with a task raising an error' do
      let(:message) { { test: true } }

      it 'outputs a log via the bot' do
        task = Class.new(Peribot::Processor) do
          def process(*)
            raise 'just testing'
          end
        end
        instance.register task

        # Only part of the log will be matched. We just want to ensure that the
        # right message gets output and that the exception isn't forgotten.
        log_msg = <<-END
          => message = #{message}
          => exception =
        END
        log_msg.gsub!(/^\s{#{log_msg.match('\s+').to_s.length - 2}}/, '')
        log_msg.strip!

        expect(bot).to receive(:log).with(/#{Regexp.quote(log_msg)}/)
        instance.accept(message).each(&:wait)
      end
    end
  end
end
