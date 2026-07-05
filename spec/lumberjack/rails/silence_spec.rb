# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::LogAtLevel do
  let(:out) { StringIO.new }
  let(:logger) { Lumberjack::Logger.new(out, level: :info, template: "{{message}}") }

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

  it "should not silence other loggers" do
    other_out = StringIO.new
    other_logger = Lumberjack::Logger.new(other_out, level: :info, template: "{{message}}")

    logger.silence do
      expect(other_logger.level).to eq(Logger::INFO)
      other_logger.info("not_silenced")
    end

    expect(other_out.string.split).to eq(["not_silenced"])
  end

  it "should silence forked loggers when the broadcast logger is silenced" do
    broadcast_logger = ActiveSupport::BroadcastLogger.new(logger)
    forked_logger = broadcast_logger.fork

    broadcast_logger.silence do
      forked_logger.info("one")
      forked_logger.error("two")
    end
    forked_logger.info("three")

    expect(out.string.split).to eq(["two", "three"])
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
