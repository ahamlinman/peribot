require 'spec_helper'

describe Peribot::Middleware::Chain do
  it 'creates a chain in subclasses' do
    subclass = Class.new Peribot::Middleware::Chain
    expect(subclass.chain).to_not be_nil
  end

  it 'creates a Task class in subclasses' do
    subclass = Class.new Peribot::Middleware::Chain

    expect(subclass::Task).to be_instance_of(Class)
    expect(subclass::Task.ancestors).to include(Peribot::Middleware::Task)
  end

  it 'causes subclasses to be singletons' do
    subclass = Class.new Peribot::Middleware::Chain

    expect(subclass).to respond_to(:instance)
    expect { subclass.new }.to raise_error(NoMethodError)
    expect(subclass.instance).to eq(subclass.instance)
  end

  describe '#accept' do
    it 'schedules and returns a Concurrent::Promise' do
      chain_class = Class.new Peribot::Middleware::Chain
      promise = chain_class.instance.accept('test' => true)

      expect(promise).to be_instance_of(Concurrent::Promise)
    end

    it 'causes a promise to be executed' do
      chain_class = Class.new(Peribot::Middleware::Chain) do
        def end_action(message)
          puts message.inspect
        end
      end
      chain = chain_class.instance

      expect { chain.accept({}).value }.to output("{}\n").to_stdout
    end
  end

  describe '#promise_chain' do
    before(:each) do
      @chain = Class.new(Peribot::Middleware::Chain) do
        def end_action(message)
          @end_message = message
        end
        attr_reader :end_message
      end
    end

    it 'returns a Concurrent::Promise' do
      chain = @chain.instance
      promise = chain.promise_chain('test' => true)

      expect(promise).to be_instance_of(Concurrent::Promise)
    end

    it 'includes the end action in the promise chain' do
      chain = @chain.instance
      chain.promise_chain('test' => true).execute.value

      expect(chain.end_message).to eq('test' => true)
    end

    it 'includes tasks in the promise chain' do
      Class.new(@chain::Task) do
        def process(message)
          message['test'] = :run
          message
        end
      end

      chain = @chain.instance
      chain.promise_chain('test' => true).execute.value

      expect(chain.end_message['test']).to eq(:run)
    end

    it 'causes processing failures to get logged to stderr' do
      Class.new(@chain::Task) do
        def process(_)
          fail StopIteration
        end
      end

      chain = @chain.instance
      expect { chain.promise_chain({}).execute.value }.to output.to_stderr
    end
  end
end
