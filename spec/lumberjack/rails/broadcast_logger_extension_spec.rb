# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::BroadcastLoggerExtension do
  describe "logging methods" do
    let(:out) { StringIO.new }
    let(:logger) { Lumberjack::Logger.new(out, template: ":message - :attributes") }
    let(:standard_logger_out) { StringIO.new }
    let(:standard_logger) { ::Logger.new(standard_logger_out) }
    let(:broadcast_logger) { ActiveSupport::BroadcastLogger.new(logger, standard_logger) }

    it "sends forked logger output back to the broadcast logger" do
      forked_logger = broadcast_logger.fork(attributes: {foo: "bar"})
      forked_logger.info("test")
      expect(out.string).to include("test")
      expect(standard_logger_out.string).to include("test")
    end

    it "can tag logs in a block" do
      broadcast_logger.tag(foo: "bar") do
        broadcast_logger.info("test")
      end
      expect(out.string).to include("foo:bar")
      expect(standard_logger_out.string).to_not include("foo")
    end

    it "can tag logs in the debug method" do
      broadcast_logger.debug("Debug message", foo: "bar")
      expect(out.string).to include("Debug message - [foo:bar]")
      expect(standard_logger_out.string).to include("Debug message")
    end

    it "can tag logs in the info method" do
      broadcast_logger.info("Info message", foo: "bar")
      expect(out.string).to include("Info message - [foo:bar]")
      expect(standard_logger_out.string).to include("Info message")
    end

    it "can tag logs in the warn method" do
      broadcast_logger.warn("Warn message", foo: "bar")
      expect(out.string).to include("Warn message - [foo:bar]")
      expect(standard_logger_out.string).to include("Warn message")
    end

    it "can tag logs in the error method" do
      broadcast_logger.error("Error message", foo: "bar")
      expect(out.string).to include("Error message - [foo:bar]")
      expect(standard_logger_out.string).to include("Error message")
    end

    it "can tag logs in the fatal method" do
      broadcast_logger.fatal("Fatal message", foo: "bar")
      expect(out.string).to include("Fatal message - [foo:bar]")
      expect(standard_logger_out.string).to include("Fatal message")
    end

    it "can tag logs in the unknown method" do
      broadcast_logger.unknown("Unknown message", foo: "bar")
      expect(out.string).to include("Unknown message - [foo:bar]")
      expect(standard_logger_out.string).to include("Unknown message")
    end

    it "can log to a lumberjack logger with the trace method" do
      logger.level = :trace
      standard_logger.level = Lumberjack::Severity::TRACE
      broadcast_logger.trace("Trace message", foo: "bar")
      expect(out.string).to include("Trace message - [foo:bar]")
      expect(standard_logger_out.string).to be_empty
    end

    it "can tag logs in the add method" do
      broadcast_logger.add(Logger::INFO, "Add message", foo: "bar")
      expect(out.string).to include("Add message - [foo:bar]")
      expect(standard_logger_out.string).to include("Add message")
    end

    it "can tag logs in the log method" do
      broadcast_logger.log(Logger::INFO, "Log message", foo: "bar")
      expect(out.string).to include("Log message - [foo:bar]")
      expect(standard_logger_out.string).to include("Log message")
    end
  end

  describe "multiple yield protection" do
    let(:logger) { Lumberjack::Logger.new(:test) }
    let(:other_logger) { Lumberjack::Logger.new(:test, template: ":message") }
    let(:broadcast_logger) do
      ActiveSupport::BroadcastLogger.new(logger).tap do |bl|
        bl.broadcasts << other_logger
      end
    end

    it "does not allow multiple lumberjack loggers in the initializer" do
      expect {
        ActiveSupport::BroadcastLogger.new(logger, other_logger)
      }.to raise_error(ArgumentError, "Only one Lumberjack logger is allowed")
    end

    it "does not yield multiple times when calling log_at and does not log any warnings" do
      n = 0
      broadcast_logger.log_at(Logger::INFO) do
        n += 1
      end
      expect(n).to eq(1)
      expect(logger.device.entries).to be_empty
      expect(other_logger.device.entries).to be_empty
    end

    it "does not yield multiple times when calling silence and does not log any warnings" do
      n = 0
      broadcast_logger.silence do
        n += 1
      end
      expect(n).to eq(1)
      expect(other_logger.device.entries).to be_empty
    end

    it "does not yield multiple times when calling with_level and does not log any warnings" do
      n = 0
      broadcast_logger.with_level(:info) do
        n += 1
      end
      expect(n).to eq(1)
      expect(logger.device.entries).to be_empty
      expect(other_logger.device.entries).to be_empty
    end

    it "does not yield multiple when calling tag with a block and logs warnings" do
      n = 0
      broadcast_logger.tag(foo: "bar") do
        n += 1
      end
      expect(n).to eq(1)
      expect(logger.device).to include(severity: :warn, message: /It was called on this logger/)
      expect(other_logger.device).to include(severity: :warn, message: /It was not called on this logger/)
    end

    it "does not yield multiple when calling context with a block and logs warnings" do
      n = 0
      broadcast_logger.context do
        n += 1
      end
      expect(n).to eq(1)
      expect(logger.device).to include(severity: :warn, message: /It was called on this logger/)
      expect(other_logger.device).to include(severity: :warn, message: /It was not called on this logger/)
    end

    it "does not yield multiple when calling with_progname with a block and logs warnings" do
      n = 0
      broadcast_logger.with_progname("MyApp") do
        n += 1
      end
      expect(n).to eq(1)
      expect(logger.device).to include(severity: :warn, message: /It was called on this logger/)
      expect(other_logger.device).to include(severity: :warn, message: /It was not called on this logger/)
    end

    it "does not yield multiple when calling untagged with a block and logs warnings" do
      n = 0
      broadcast_logger.untagged do
        n += 1
      end
      expect(n).to eq(1)
      expect(logger.device).to include(severity: :warn, message: /It was called on this logger/)
      expect(other_logger.device).to include(severity: :warn, message: /It was not called on this logger/)
    end

    context "when there is not a lumberjack logger" do
      let(:logger) { Logger.new(StringIO.new) }
      let(:broadcast_logger) { ActiveSupport::BroadcastLogger.new(logger) }

      it "yields when calling log_at" do
        n = 0
        broadcast_logger.log_at(Logger::INFO) do
          n += 1
        end
        expect(n).to eq(1)
      end

      it "yields when calling silence" do
        n = 0
        broadcast_logger.silence do
          n += 1
        end
        expect(n).to eq(1)
      end

      it "yields when calling with_level" do
        n = 0
        broadcast_logger.with_level(:info) do
          n += 1
        end
        expect(n).to eq(1)
      end

      it "yields when calling tag" do
        n = 0
        broadcast_logger.tag(foo: "bar") do
          n += 1
        end
        expect(n).to eq(1)
      end

      it "yields when calling context" do
        n = 0
        broadcast_logger.context do
          n += 1
        end
        expect(n).to eq(1)
      end

      it "yields when calling with_progname with a block" do
        n = 0
        broadcast_logger.with_progname("MyApp") do
          n += 1
        end
        expect(n).to eq(1)
      end

      it "yields when calling untagged with a block" do
        n = 0
        broadcast_logger.untagged do
          n += 1
        end
        expect(n).to eq(1)
      end
    end
  end
end
