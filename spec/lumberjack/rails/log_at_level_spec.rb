# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::LogAtLevel do
  let(:out) { StringIO.new }
  let(:logger) { Lumberjack::Logger.new(out, level: :info, template: "{{message}}") }

  it "should temporarily set the log level for a block" do
    out = StringIO.new
    logger = Lumberjack::Logger.new(out, level: Logger::INFO, template: "{{message}}")
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

  it "should not change the local level of other loggers" do
    other_logger = Lumberjack::Logger.new(StringIO.new, level: :info, template: "{{message}}")

    logger.log_at(Logger::ERROR) do
      expect(logger.level).to eq(Logger::ERROR)
      expect(other_logger.local_level).to be_nil
      expect(other_logger.level).to eq(Logger::INFO)
    end
  end

  it "should apply the local level to forked loggers" do
    forked_logger = logger.fork

    logger.log_at(Logger::ERROR) do
      expect(forked_logger.level).to eq(Logger::ERROR)
      forked_logger.info("one")
      forked_logger.error("two")
    end
    forked_logger.info("three")

    expect(out.string.split).to eq(["two", "three"])
  end
end
