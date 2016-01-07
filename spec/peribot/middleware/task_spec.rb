require 'spec_helper'

describe Peribot::Middleware::Task do
  describe '#process' do
    it 'fails when not implemented' do
      task = Peribot::Middleware::Task.new
      expect { task.process({}) }.to raise_error(RuntimeError)
    end
  end
end
