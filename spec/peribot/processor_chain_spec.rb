require 'spec_helper'

describe Peribot::ProcessorChain do
  let(:bot) { instance_double(Peribot::Bot) }
  let(:instance) { Peribot::ProcessorChain.new bot }

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
    it 'returns a Concurrent::Promise' do
      promise = instance.accept('test' => true)
      expect(promise).to be_instance_of(Concurrent::Promise)
    end

    context 'with an end action' do
      it 'executes the end action' do
        chain = Peribot::ProcessorChain.new(bot) do |msg|
          puts msg.inspect
        end

        expect { chain.accept({}).wait }.to output("{}\n").to_stdout
      end
    end

    context 'with one task' do
      it 'executes the task' do
        task = Class.new(Peribot::Processor) do
          def process(msg)
            puts msg.inspect
          end
        end
        instance.register task

        expect { instance.accept({}).wait }.to output("{}\n").to_stdout
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
        instance.accept({}).wait
      end
    end

    context 'with a task raising an error' do
      it 'outputs a log via the bot' do
        task = Class.new(Peribot::Processor) do
          def process(*)
            fail 'just testing'
          end
        end
        instance.register task

        msg = <<-END
        Error in processing chain:
          => message = {}
          => exception = #<RuntimeError: just testing>
        END
        msg.gsub!(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip!

        expect(bot).to receive(:log).with(msg)
        instance.accept({}).wait
      end
    end

    context 'with a task raising the chain stop exception' do
      it 'stops processing without logging' do
        chain = Peribot::ProcessorChain.new(bot) do
          fail 'the end action was reached'
        end

        task = Class.new(Peribot::Processor) do
          def process(*)
            fail Peribot::ProcessorChain::Stop, 'this should not be seen'
          end
        end
        chain.register task

        expect(bot).to_not receive(:log)
        chain.accept({}).wait
      end
    end
  end
end
