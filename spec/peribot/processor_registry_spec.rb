require 'spec_helper'

describe Peribot::ProcessorRegistry do
  describe '#register' do
    it 'registers processors' do
      p = proc {}

      registry = described_class.new
      expect(registry.register(p)).to be true
    end

    it 'does not register processors more than once' do
      p = proc {}

      registry = described_class.new
      registry.register p
      expect(registry.register(p)).to be false
    end
  end

  describe '#list' do
    it 'returns a list of processors' do
      procs = [proc {}, proc {}]
      registry = described_class.new
      procs.each(&registry.method(:register))

      expect(registry.list).to include(*procs)
    end
  end
end
