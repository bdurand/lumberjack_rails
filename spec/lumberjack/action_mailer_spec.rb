# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "ActionMailer integration" do
  require "action_mailer"

  class TestMailer < ActionMailer::Base
    default from: "test@example.com"

    class << self
      attr_accessor :last_context_result
    end

    def test_email(lumberjack_logger)
      self.class.last_context_result = lumberjack_logger.context?

      mail(
        to: "test@example.com",
        subject: "Test",
        body: "Test body"
      )
    end
  end

  let(:logger) { Lumberjack::Logger.new(:test) }
  let(:standard_logger) { ::Logger.new(File::NULL) }

  before(:all) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
  end

  after do
    Rails.logger = nil
    ActionMailer::Base.logger = nil
    TestMailer.last_context_result = nil
    ActionMailer::Base.deliveries.clear
  end

  it "should add a context block to the Rails logger" do
    Rails.logger = logger
    ActionMailer::Base.logger = standard_logger
    TestMailer.test_email(logger).deliver_now
    expect(TestMailer.last_context_result).to be true
  end

  it "should add a context block to the ActionMailer logger" do
    Rails.logger = standard_logger
    ActionMailer::Base.logger = logger
    TestMailer.test_email(logger).deliver_now
    expect(TestMailer.last_context_result).to be true
  end

  it "should not raise an error when Rails.logger is nil" do
    Rails.logger = nil
    ActionMailer::Base.logger = logger
    TestMailer.test_email(logger).deliver_now
    expect(TestMailer.last_context_result).to be true
  end

  it "should not raise an error when ActionMailer.logger is nil" do
    Rails.logger = logger
    ActionMailer::Base.logger = nil
    TestMailer.test_email(logger).deliver_now
    expect(TestMailer.last_context_result).to be true
  end
rescue LoadError
  skip "ActionMailer is not available"
end
