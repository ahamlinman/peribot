require 'spec_helper'

describe Peribot::Processor do
  let(:bot) { class_double(Peribot) }
  let(:task) { Peribot::Processor.new bot }

  describe '#process' do
    it 'fails when not implemented' do
      expect { task.process({}) }.to raise_error(RuntimeError)
    end
  end

  describe '#stop_processing' do
    it 'raises the processor chain stop exception' do
      expect { task.stop_processing }.to raise_error(
        Peribot::ProcessorChain::Stop)
    end
  end
end
