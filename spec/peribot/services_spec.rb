require 'spec_helper'

describe Peribot::Services do
  it 'has an iterable list of services' do
    expect(Peribot::Services.list).to respond_to(:each)
  end
end
