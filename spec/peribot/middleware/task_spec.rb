require 'spec_helper'

describe Peribot::Middleware::Task do
  let(:task) { Peribot::Middleware::Task.new }

  describe '#process' do
    it 'fails when not implemented' do
      expect { task.process({}) }.to raise_error(RuntimeError)
    end
  end

  describe '#stop_processing' do
    it 'raises Peribot::Middleware::Stop' do
      expect { task.stop_processing }.to raise_error(Peribot::Middleware::Stop)
    end
  end
end
