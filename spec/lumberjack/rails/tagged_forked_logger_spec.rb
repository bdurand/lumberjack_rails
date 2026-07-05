# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::TaggedForkedLogger do
  let(:out) { StringIO.new }
  let(:logger) { Lumberjack::Logger.new(out, level: :info, template: "{{message}} {{attributes}}") }

  describe "#tagged" do
    it "delegates tagged to the parent logger" do
      forked_logger = logger.fork
      forked_logger.tagged("foo") do
        forked_logger.info("test")
      end
      expect(out.string).to include("test")
      expect(out.string).to include("foo")
    end

    it "still calls the block when the parent logger does not support tagged" do
      parent = Object.new
      def parent.add_entry(*)
      end

      def parent.level
        0
      end

      def parent.progname
        nil
      end
      forked_logger = Lumberjack::ForkedLogger.new(parent)

      block_called = false
      result = forked_logger.tagged("foo") do
        block_called = true
        :retval
      end

      expect(block_called).to be true
      expect(result).to eq(:retval)
    end

    it "returns self when the parent logger does not support tagged and no block is given" do
      parent = Object.new
      def parent.add_entry(*)
      end

      def parent.level
        0
      end

      def parent.progname
        nil
      end
      forked_logger = Lumberjack::ForkedLogger.new(parent)

      expect(forked_logger.tagged("foo")).to equal(forked_logger)
    end
  end

  describe "#local_level" do
    it "shares the local level with the parent logger" do
      forked_logger = logger.fork

      logger.log_at(Logger::ERROR) do
        expect(forked_logger.local_level).to eq(Logger::ERROR)
        expect(forked_logger.level).to eq(Logger::ERROR)
      end

      expect(forked_logger.local_level).to be_nil
    end

    it "sets the local level on the parent logger" do
      forked_logger = logger.fork

      forked_logger.log_at(Logger::ERROR) do
        expect(logger.local_level).to eq(Logger::ERROR)
      end

      expect(logger.local_level).to be_nil
    end
  end
end
