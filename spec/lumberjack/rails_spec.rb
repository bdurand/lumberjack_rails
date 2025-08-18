# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Lumberjack::Rails do
  let(:out) { StringIO.new }

  describe "tagged logging support" do
    let(:logger) { Lumberjack::Logger.new(out, level: :info, template: ":message - :tags") }

    it "should wrap a Lumberjack logger as a tagged logger" do
      tagged_logger = ActiveSupport::TaggedLogging.new(logger)
      tagged_logger.tagged("foo", "bar") { tagged_logger.info("test") }
      expect(out.string.chomp).to eq 'test - [tagged:["foo", "bar"]]'
    end

    it "should still work for other kinds of loggers enhanced with ActiveSupport::TaggedLogging" do
      standard_logger = ::Logger.new(out)
      tagged_logger = ActiveSupport::TaggedLogging.new(standard_logger)
      tagged_logger.tagged("foo", "bar") { tagged_logger.info("test") }
      expect(out.string.chomp).to eq "[foo] [bar] test"
    end

    it "should work with a broadcast logger" do
      broadcast_logger = ActiveSupport::BroadcastLogger.new(logger)
      broadcast_logger.tagged("foo", "bar") do
        broadcast_logger.info("test")
      end
      expect(out.string.chomp).to eq "test - [tagged:[\"foo\", \"bar\"]]"
    end

    it "should work with local loggers" do
      tagged_logger = ActiveSupport::TaggedLogging.new(logger)
      tagged_logger.tagged("foo") do
        local_logger = tagged_logger.local_logger(attributes: {bip: "bap"})
        local_logger.tagged("bar") do
          local_logger.info("test")
        end
      end
      expect(out.string.chomp).to eq "test - [bip:bap] [tagged:[\"foo\", \"bar\"]]"
    end
  end

  describe "broadcast logger support" do
    let(:logger) { Lumberjack::Logger.new(out, level: :info, template: ":message - :tags") }
    let(:standard_logger_out) { StringIO.new }
    let(:standard_logger) { ::Logger.new(standard_logger_out) }
    let(:broadcast_logger) { ActiveSupport::BroadcastLogger.new(logger, standard_logger) }

    it "sends local logger output back to the broadcast logger" do
      local_logger = broadcast_logger.local_logger(tags: {foo: "bar"})
      local_logger.info("test")
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
      thread = Thread.new do
        logger.local_level = :warn
        expect(logger.local_level).to eq(Logger::WARN)
        expect(logger.level).to eq(Logger::WARN)
      end

      thread.join
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
