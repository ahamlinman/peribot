require 'spec_helper'

describe Peribot::Services do
  after(:each) do
    Peribot::Services.list.clear
  end

  it 'has an iterable list of services' do
    expect(Peribot::Services.list).to respond_to(:each)
  end

  describe '.dispatch' do
    let(:base) { Peribot::Services::Base }
    let(:postprocessor) { Peribot::Postprocessor.instance }
    let(:message) { { 'group_id' => '1234', 'text' => 'Test' } }
    let(:first_reply) { { 'group_id' => '1234', 'text' => 'Success!' } }
    let(:second_reply) { { 'group_id' => '1234', 'text' => 'Another!' } }

    context 'with one service' do
      it 'dispatches to that service' do
        Class.new(base) do
          def handler(*)
            'Success!'
          end
          on_message :handler
        end

        expect(postprocessor).to receive(:accept).with(first_reply)

        Peribot::Services.dispatch(message).value.each(&:value)
      end
    end

    context 'with multiple services' do
      it 'dispatches to all services' do
        Class.new(base) do
          def handler(*)
            'Success!'
          end
          on_message :handler
        end

        Class.new(base) do
          def handler(*)
            'Another!'
          end
          on_message :handler
        end

        expect(postprocessor).to receive(:accept).with(first_reply)
        expect(postprocessor).to receive(:accept).with(second_reply)

        Peribot::Services.dispatch(message).value.each(&:value)
      end
    end
  end
end
