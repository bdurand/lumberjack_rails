# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::ActionControllerExtension do
  require "action_controller"

  class TestController < ActionController::Base
    class << self
      attr_accessor :last_context_result
    end

    attr_accessor :test_logger

    # Simulate what happens during controller action
    def test_context_handling
      # Manually trigger the around_action callback behavior
      # Pass the logger like ActionController does: logger_context(logger, &block)
      Lumberjack::Rails.logger_context(logger) do
        self.class.last_context_result = test_logger&.in_context?
      end
    end

    # Provide a logger method that returns the ActionController logger
    def logger
      ActionController::Base.logger
    end

    # Minimal controller initialization to avoid complex mocking
    def initialize
      # Don't call super - avoid ActionController's complex initialization
    end
  end

  let(:logger) { Lumberjack::Logger.new(:test) }
  let(:standard_logger) { ::Logger.new(File::NULL) }

  after do
    Rails.logger = nil
    ActionController::Base.logger = nil
    TestController.last_context_result = nil
  end

  it "should add a context block to the Rails logger" do
    Rails.logger = logger
    ActionController::Base.logger = standard_logger

    controller = TestController.new
    controller.test_logger = logger
    controller.test_context_handling

    expect(TestController.last_context_result).to be true
  end

  it "should add a context block to the ActionController logger" do
    Rails.logger = standard_logger
    ActionController::Base.logger = logger

    controller = TestController.new
    controller.test_logger = logger
    controller.test_context_handling

    expect(TestController.last_context_result).to be true
  end

  it "should not raise an error when Rails.logger is nil" do
    Rails.logger = nil
    ActionController::Base.logger = logger

    controller = TestController.new
    controller.test_logger = logger
    controller.test_context_handling

    # Even when Rails.logger is nil, ActionController logger can still provide context
    expect(TestController.last_context_result).to be true
  end

  it "should not raise an error when ActionController logger is nil" do
    Rails.logger = logger
    ActionController::Base.logger = nil

    controller = TestController.new
    controller.test_logger = logger
    controller.test_context_handling

    expect(TestController.last_context_result).to be true
  end
rescue LoadError
  skip "ActionController is not available"
end
