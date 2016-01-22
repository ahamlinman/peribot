require 'spec_helper'

describe Peribot::ProcessorChain do
  let(:bot) { instance_double(Peribot::Bot) }
  let(:instance) { Peribot::ProcessorChain.new bot }

  it 'contains an accessible list of tasks' do
    expect(instance).to respond_to(:tasks)
  end

  describe '#register' do
    let(:task) { Class.new(Peribot::Middleware::Task) }

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

        expect { chain.accept({}).value }.to output("{}\n").to_stdout
      end
    end

    context 'with one task' do
      it 'executes the task' do
        task = Class.new(Peribot::Middleware::Task) do
          def process(msg)
            puts msg.inspect
          end
        end
        instance.register task

        expect { instance.accept({}).value }.to output("{}\n").to_stdout
      end
    end

    context 'with a task raising an error' do
      it 'outputs a log via the bot' do
        task = Class.new(Peribot::Middleware::Task) do
          def process(*)
            fail 'just testing'
          end
        end
        instance.register task

        expect(bot).to receive(:log)
        instance.accept({}).value
      end
    end

    context 'with a task raising Peribot::Middleware::Stop' do
      it 'stops processing without logging' do
        chain = Peribot::ProcessorChain.new(bot) do
          fail 'the end action was reached'
        end

        task = Class.new(Peribot::Middleware::Task) do
          def process(*)
            fail Peribot::Middleware::Stop, 'this should not be seen'
          end
        end
        chain.register task

        expect(bot).to_not receive(:log)
        chain.accept({}).value
      end
    end
  end
end
