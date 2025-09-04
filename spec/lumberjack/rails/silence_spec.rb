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
