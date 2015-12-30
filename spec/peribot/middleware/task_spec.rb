require 'spec_helper'

describe Peribot::Middleware::Task do
  describe '.build_class' do
    before(:each) do
      @chain = Class.new do |cls|
        cls.instance_variable_set :@chain, []
        class << cls; attr_accessor :chain; end
      end
    end

    it 'builds a new Task subclass' do
      task_class = Peribot::Middleware::Task.build_class @chain

      expect(task_class).not_to be_nil
      expect(task_class).to be_instance_of(Class)
      expect(task_class.ancestors).to include(Peribot::Middleware::Task)
    end

    it 'makes subclasses add themselves to the chain class' do
      task_class = Peribot::Middleware::Task.build_class @chain
      task_subclass = Class.new(task_class)

      expect(@chain.chain).to include(task_subclass)
    end
  end

  describe '#process' do
    it 'fails when not implemented' do
      task = Peribot::Middleware::Task.new
      expect { task.process({}) }.to raise_error(RuntimeError)
    end
  end
end
