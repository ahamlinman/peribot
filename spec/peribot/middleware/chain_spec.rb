require 'spec_helper'

describe Peribot::Middleware::Chain do
  it 'contains an accessible list of tasks' do
    instance = Peribot::Middleware::Chain.new
    expect(instance).to respond_to(:tasks)
  end

  describe '#register' do
    it 'adds a task to the task list' do
      instance = Peribot::Middleware::Chain.new
      task = Class.new(Peribot::Middleware::Task)
      instance.register task

      expect(instance.tasks).to include(task)
    end
  end

  describe '#accept' do
    it 'returns a Concurrent::Promise' do
      instance = Peribot::Middleware::Chain.new
      promise = instance.accept('test' => true)

      expect(promise).to be_instance_of(Concurrent::Promise)
    end

    context 'with an end action' do
      it 'executes the end action' do
        chain = Peribot::Middleware::Chain.new do |msg|
          puts msg.inspect
        end

        expect { chain.accept({}).value }.to output("{}\n").to_stdout
      end
    end

    context 'with one task' do
      it 'executes the task' do
        chain = Peribot::Middleware::Chain.new
        task = Class.new(Peribot::Middleware::Task) do
          def process(msg)
            puts msg.inspect
          end
        end
        chain.register task

        expect { chain.accept({}).value }.to output("{}\n").to_stdout
      end
    end

    context 'with a task raising an error' do
      it 'logs to stderr' do
        chain = Peribot::Middleware::Chain.new
        task = Class.new(Peribot::Middleware::Task) do
          def process(*)
            fail 'just testing'
          end
        end
        chain.register task

        expect { chain.accept({}).value }.to output.to_stderr
      end
    end
  end
end
