require 'spec_helper'

shared_examples 'a middleware chain' do
  after(:each) do
    described_class.chain.clear
  end

  it 'is a middlware chain' do
    expect(described_class.ancestors).to include(Peribot::Middleware::Chain)
  end

  it 'contains a task class' do
    expect(described_class::Task).to_not be_nil
  end

  it 'has tasks placed in its chain' do
    Class.new(described_class::Task)
    expect(described_class.chain.length).to eq(1)
  end
end
