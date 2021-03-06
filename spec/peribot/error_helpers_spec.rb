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
  let(:message) do
    { service: :groupme, group: 'groupme/1', text: 'Testing!' }
  end
  let(:error) { FakeError.new 'sample error' }

  describe '#log_failure' do
    context 'with an error and a message' do
      let(:output) do
        msg = <<-ERR
        (#{Time.now}) Error in ErrorTester
          => message = #{message}
          => exception = #{error.inspect}
          => backtrace:
              line one
              line two
        ERR
        msg.gsub(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip
      end

      it 'logs the message and error' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure(
            message: message,
            error: error,
            logger: bot.method(:log)
          )
        end
      end
    end

    context 'with only an error' do
      let(:output) do
        msg = <<-ERR
        (#{Time.now}) Error in ErrorTester
          => exception = #{error.inspect}
          => backtrace:
              line one
              line two
        ERR
        msg.gsub(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip
      end

      it 'logs the error' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure error: error, logger: bot.method(:log)
        end
      end
    end

    context 'with only a message' do
      let(:output) do
        msg = <<-ERR
        (#{Time.now}) Error in ErrorTester
          => message = #{message}
        ERR
        msg.gsub(/^\s{#{msg.match('\s+').to_s.length}}/, '').strip
      end

      it 'logs the message and error' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure message: message, logger: bot.method(:log)
        end
      end
    end

    context 'with no parameters' do
      let(:output) { "(#{Time.now}) Error in ErrorTester" }

      it 'logs a generic message' do
        Timecop.freeze do
          expect(bot).to receive(:log).with(output)
          tester.log_failure logger: bot.method(:log)
        end
      end
    end
  end
end
