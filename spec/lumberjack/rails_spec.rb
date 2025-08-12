# frozen_string_literal: true

require_relative "../spec_helper"

describe Lumberjack::Rails do
  let(:out) { StringIO.new }

  describe "tagged logging support" do
    let(:logger) { Lumberjack::Logger.new(out, level: :info, template: ":message - :tags") }

    it "should wrap a Lumberjack logger as a tagged logger" do
      tagged_logger = ActiveSupport::TaggedLogging.new(logger)
      tagged_logger.tagged("foo", "bar") { tagged_logger.info("test") }
      expect(out.string.chomp).to eq 'test - [tagged:["foo", "bar"]]'
    end

    it "should wrap other kinds of logger with ActiveSupport Tagged logger" do
      logger = ::Logger.new(out)
      tagged_logger = ActiveSupport::TaggedLogging.new(logger)
      tagged_logger.tagged("foo", "bar") { tagged_logger.info("test") }
      expect(out.string.chomp).to eq "[foo] [bar] test"
    end
  end

  describe "#log_at" do
    let(:logger) { Lumberjack::Logger.new(out, level: :info, template: ":message") }

    it "should temporarily set the log level for a block" do
      out = StringIO.new
      logger = Lumberjack::Logger.new(out, level: Logger::INFO, template: ":message")
      logger.info("one")
      logger.log_at(Logger::WARN) do
        expect(logger.level).to eq(Logger::WARN)
        expect(logger.local_level).to eq(Logger::WARN)
        logger.warn("two")
        logger.info("three")
      end
      expect(logger.local_level).to be_nil
      logger.info("four")
      expect(out.string.split).to eq(["one", "two", "four"])
    end

    it "should set the local level in isolation" do
      fiber = Fiber.new do
        logger.local_level = :warn
        expect(logger.local_level).to eq(Logger::WARN)
        expect(logger.level).to eq(Logger::WARN)
      end

      expect(logger.local_level).to be_nil
      expect(logger.level).to eq(Logger::INFO)
    end
  end

  describe "#silence" do
    let(:logger) { Lumberjack::Logger.new(out, level: :info, template: ":message") }

    it "should be able to silence the log in a block" do
      logger.info("one")
      logger.silence do
        expect(logger.level).to eq(Logger::ERROR)
        logger.info("two")
        logger.error("three")
      end
      logger.info("four")
      expect(out.string.split).to eq(["one", "three", "four"])
    end

    it "should be able to customize the level of silence in a block" do
      logger.info("one")
      logger.silence(Logger::FATAL) do
        expect(logger.level).to eq(Logger::FATAL)
        logger.info("two")
        logger.error("three")
        logger.fatal("woof")
      end
      logger.info("four")
      expect(out.string.split).to eq(["one", "woof", "four"])
    end

    it "should be able to customize the level of silence in a block with a symbol" do
      logger.info("one")
      logger.silence(:fatal) do
        expect(logger.level).to eq(Logger::FATAL)
        logger.info("two")
        logger.error("three")
        logger.fatal("woof")
      end
      logger.info("four")
      expect(out.string.split).to eq(["one", "woof", "four"])
    end

    it "should not be able to silence the logger if silencing is disabled" do
      save_value = logger.silencer
      begin
        logger.silencer = false
        logger.info("one")
        logger.silence do
          expect(logger.level).to eq(Logger::INFO)
          logger.info("two")
          logger.error("three")
        end
        logger.info("four")
        expect(out.string.split).to eq(["one", "two", "three", "four"])
      ensure
        logger.silencer = save_value
      end
    end
  end
end
