# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ActionCable integration" do
  require "action_cable"

  class TestConnection < ActionCable::Connection::Base
    class << self
      attr_accessor :last_context_result
    end

    attr_accessor :test_logger

    # Simulate what happens during connection lifecycle
    def test_context_handling
      # Manually trigger the around_command callback behavior
      # Pass the logger like ActionCable does: logger_context(logger, &block)
      Lumberjack::Rails.logger_context(logger) do
        self.class.last_context_result = test_logger&.in_context?
      end
    end

    # Provide a logger method that returns the ActionCable logger
    def logger
      ActionCable::Server::Base.config.logger
    end

    # Minimal connection initialization to avoid complex mocking
    def initialize
      # Don't call super - avoid ActionCable's complex initialization
    end
  end

  let(:logger) { Lumberjack::Logger.new(:test) }
  let(:standard_logger) { ActiveSupport::TaggedLogging.new(::Logger.new(File::NULL)) }

  after do
    Rails.logger = nil
    ActionCable::Server::Base.config.logger = nil
    TestConnection.last_context_result = nil
  end

  it "should add a context block to the Rails logger" do
    Rails.logger = logger
    ActionCable::Server::Base.config.logger = standard_logger

    connection = TestConnection.new
    connection.test_logger = logger
    connection.test_context_handling

    expect(TestConnection.last_context_result).to be true
  end

  it "should add a context block to the ActionCable logger" do
    Rails.logger = standard_logger
    ActionCable::Server::Base.config.logger = logger

    connection = TestConnection.new
    connection.test_logger = logger
    connection.test_context_handling

    expect(TestConnection.last_context_result).to be true
  end

  it "should not raise an error when Rails.logger is nil" do
    Rails.logger = nil
    ActionCable::Server::Base.config.logger = logger

    connection = TestConnection.new
    connection.test_logger = logger
    connection.test_context_handling

    # Even when Rails.logger is nil, ActionCable logger can still provide context
    expect(TestConnection.last_context_result).to be true
  end

  it "should not raise an error when ActionCable logger is nil" do
    Rails.logger = logger
    ActionCable::Server::Base.config.logger = nil

    connection = TestConnection.new
    connection.test_logger = logger
    connection.test_context_handling

    expect(TestConnection.last_context_result).to be true
  end
rescue LoadError
  skip "ActionCable is not available"
end
