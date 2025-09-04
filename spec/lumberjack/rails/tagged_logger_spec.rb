# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveSupport::TaggedLogging do
  let(:out) { StringIO.new }
  let(:logger) { Lumberjack::Logger.new(out, level: :info, template: "{{message}} - {{attributes}}") }

  it "should wrap a Lumberjack logger as a tagged logger" do
    tagged_logger = ActiveSupport::TaggedLogging.new(logger)
    tagged_logger.tagged("foo", "bar") { tagged_logger.info("test") }
    expect(out.string.chomp).to eq 'test - [tags:["foo", "bar"]]'
  end

  it "can still pass attributes with a tagged logger message" do
    tagged_logger = ActiveSupport::TaggedLogging.new(logger)
    tagged_logger.info("test", foo: "bar")
    expect(out.string.chomp).to eq "test - [foo:bar]"
  end

  it "can still pass attributes to the logger returned from tagged" do
    tagged_logger = ActiveSupport::TaggedLogging.new(logger)
    tagged_logger.tagged("foo", "bar") { tagged_logger.info("test", bip: "bap") }
    expect(out.string.chomp).to eq "test - [bip:bap] [tags:[\"foo\", \"bar\"]]"
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
    expect(out.string.chomp).to eq "test - [tags:[\"foo\", \"bar\"]]"
  end

  it "should work with forked loggers" do
    tagged_logger = ActiveSupport::TaggedLogging.new(logger)
    tagged_logger.tagged("foo") do
      forked_logger = tagged_logger.fork(attributes: {bip: "bap"})
      forked_logger.tagged("bar") do
        forked_logger.info("test")
      end
    end
    expect(out.string.chomp).to eq "test - [bip:bap] [tags:[\"foo\", \"bar\"]]"
  end
end
