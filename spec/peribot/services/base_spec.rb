require 'spec_helper'

describe Peribot::Services::Base do
  after(:each) do
    Peribot::Services.list.clear
  end

  it 'adds subclasses to the global service list' do
    subclass = Class.new(Peribot::Services::Base)
    expect(Peribot::Services.list).to include(subclass)
  end

  it 'supports message handlers in subclasses' do
    subclass = Class.new(Peribot::Services::Base) do
      def test(*); end
      on_message :test
    end

    expect(subclass.message_handlers).to contain_exactly(:test)
  end

  it 'supports command handlers in subclasses' do
    subclass = Class.new(Peribot::Services::Base) do
      def test(*); end
      on_command :cmd, :test
    end

    expect(subclass.command_handlers).to contain_exactly('cmd' => :test)
  end

  it 'supports listen handlers in subclasses' do
    subclass = Class.new(Peribot::Services::Base) do
      def test(*); end
      on_hear(/match/, :test)
    end

    expect(subclass.listen_handlers).to contain_exactly(/match/ => :test)
  end
end
