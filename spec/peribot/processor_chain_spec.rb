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
          # During mutation testing, an example was created where the end
          # action would be chained to the other tasks, but the variable would
          # still point to the end action's parent. The end action would
          # execute, but it would not be waited on. Sleeping here is a cheap
          # way to make sure that everything gets waited on properly - the test
          # is very likely to fail if the chaining isn't done right. It only
          # adds nominal overhead to the test.
          sleep 0.1
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
        instance.accept(message).wait
      end
    end

    context 'with a task raising the chain stop exception directly' do
      it 'stops processing without logging' do
        chain = Peribot::ProcessorChain.new(bot) do
          raise 'the end action was reached'
        end

        task = Class.new(Peribot::Processor) do
          def process(*)
            raise Peribot::ProcessorChain::Stop, 'this should not be seen'
          end
        end
        chain.register task

        expect(bot).to_not receive(:log)
        chain.accept({}).wait
      end

      it 'does not `break` from the rescue block' do
        promise = Concurrent::Promise.fulfill({})
        expect(Concurrent::Promise).to receive(:fulfill).and_return(promise)

        original_rescue = promise.method(:rescue)
        expect(promise).to receive(:rescue) do |&block|
          block.call(Peribot::ProcessorChain::Stop.new)

          # If the rescue block uses `break` instead of `next` when attempting
          # to skip anything further in the block, then the entire promise
          # chain will suddenly become nil (since we will not get past the part
          # above and cannot run the part below where we return the value from
          # the method's original implementation). Acting on nil as though it
          # is a promise chain will cause this test to fail, which allows us to
          # ensure that we are not using `break` inside of that block. (Using
          # `break` instead of `next` leads to infinite hangs on JRuby.)

          original_rescue.call(&block)
        end

        instance.accept({}).wait
      end
    end

    context 'with a task returning nil' do
      it 'stops processing without logging' do
        chain = Peribot::ProcessorChain.new(bot) do
          raise 'the end action was reached'
        end

        task = Class.new(Peribot::Processor) do
          def process(*)
            nil
          end
        end
        chain.register task

        expect(bot).to_not receive(:log)
        chain.accept({}).wait
      end
    end
  end
end
