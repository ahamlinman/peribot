require 'spec_helper'
require 'timecop'

describe Peribot::ErrorHelpers do
  # A simple class to test the error helpers.
  class ErrorTester
    include Peribot::ErrorHelpers

    def initialize(bot)
      @bot = bot
    end

    attr_reader :bot
    public :log_failure
  end

  # An error with a fake backtrace
  class FakeError < RuntimeError
    def backtrace
      ['line one', 'line two']
    end
  end

  let(:bot) { instance_double(Peribot::Bot) }
  let(:tester) { ErrorTester.new bot }
  let(:message) { { 'group_id' => '1', 'text' => 'Testing!' } }
  let(:error) { FakeError.new 'sample error' }

  describe '#log_failure' do
    context 'with an error and a message' do
      let(:output) do
        msg = <<-END
        (#{Time.now}) Error in ErrorTester
          => message = #{message}
          => exception = #{error.inspect}
          => backtrace:
              line one
              line two
        END
        msg.gsub(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip
      end

      it 'logs the message and error' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure message: message, error: error
        end
      end
    end

    context 'with only an error' do
      let(:output) do
        msg = <<-END
        (#{Time.now}) Error in ErrorTester
          => exception = #{error.inspect}
          => backtrace:
              line one
              line two
        END
        msg.gsub(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip
      end

      it 'logs the error' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure error: error
        end
      end
    end

    context 'with only a message' do
      let(:output) do
        msg = <<-END
        (#{Time.now}) Error in ErrorTester
          => message = #{message}
        END
        msg.gsub(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip
      end

      it 'logs the message and error' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure message: message
        end
      end
    end

    context 'with no parameters' do
      let(:output) { "(#{Time.now}) Error in ErrorTester" }

      it 'logs a generic message' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure
        end
      end
    end

    context 'with a custom logger' do
      let(:output) { "(#{Time.now}) Error in ErrorTester" }
      let(:logger) { double('logger') }

      it 'logs a generic message' do
        Timecop.freeze do
          expect(logger).to receive(:call).with(output)
          tester.log_failure logger: logger
        end
      end
    end
  end
end
