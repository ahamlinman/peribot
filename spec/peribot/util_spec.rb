require 'spec_helper'

describe Peribot::Util do
  describe '.process_replies' do
    let(:original) { { service: :msgr, group: 'msgr/1234', text: '#hi there' } }

    let(:inputs) do
      [
        'A reply!',
        nil,
        [nil, 'Another!'],
        [{ service: :grpy, group: 'grpy/2356', text: 'Wow!' }]
      ]
    end

    let(:outputs) do
      [
        { service: :msgr, group: 'msgr/1234', text: 'A reply!' },
        { service: :msgr, group: 'msgr/1234', text: 'Another!' },
        { service: :grpy, group: 'grpy/2356', text: 'Wow!' }
      ]
    end

    it 'normalizes an array of replies and calls an acceptor' do
      actual = []
      described_class.process_replies(inputs, original, &actual.method(:<<))
      expect(actual).to eq(outputs)
    end
  end
end
