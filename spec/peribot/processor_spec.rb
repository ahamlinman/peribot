require 'spec_helper'

describe Peribot::Processor do
  let(:bot) { instance_double(Peribot::Bot) }
  let(:task) { Peribot::Processor.new bot }

  it 'provides access to the bot it was initialized with' do
    task = Class.new(Peribot::Processor) do
      def process(*)
        puts bot.class
      end
    end

    expect { task.new(Object.new).process({}) }
      .to output("Object\n").to_stdout
  end

  describe '#process' do
    it 'fails when not implemented' do
      msg = 'process method not implemented in Peribot::Processor'
      expect { task.process({}) }.to raise_error(msg)
    end
  end

  describe '#stop_processing' do
    it 'raises the processor chain stop exception' do
      expect { task.stop_processing }.to raise_error(
        Peribot::ProcessorChain::Stop)
    end
  end
end
