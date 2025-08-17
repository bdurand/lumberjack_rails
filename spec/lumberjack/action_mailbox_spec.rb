# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "ActionMailbox integration" do
  require "action_mailbox"

  class TestMailbox < ActionMailbox::Base
    class << self
      attr_accessor :last_context_result
    end

    attr_accessor :test_logger

    def process
      self.class.last_context_result = test_logger&.context?
    end
  end

  let(:logger) { Lumberjack::Logger.new(:test) }
  let(:standard_logger) { ::Logger.new(File::NULL) }

  after do
    Rails.logger = nil
    ActionMailbox.logger = nil
    TestMailbox.last_context_result = nil
  end

  # Create a simple mock inbound email object with just the methods we need
  def create_test_inbound_email
    double("InboundEmail").tap do |email|
      # Methods called during processing
      allow(email).to receive(:instrumentation_payload).and_return({source: "test"})
      allow(email).to receive(:processing!).and_return(nil)
      allow(email).to receive(:delivered!).and_return(nil)

      # Status check methods
      allow(email).to receive(:bounced?).and_return(false)
      allow(email).to receive(:failed?).and_return(false)
      allow(email).to receive(:processed?).and_return(false)
    end
  end

  it "should add a context block to the Rails logger" do
    Rails.logger = logger
    ActionMailbox.logger = standard_logger

    mailbox = TestMailbox.new(create_test_inbound_email)
    mailbox.test_logger = logger
    mailbox.perform_processing

    expect(TestMailbox.last_context_result).to be true
  end

  it "should add a context block to the ActionMailer logger" do
    Rails.logger = standard_logger
    ActionMailbox.logger = logger

    mailbox = TestMailbox.new(create_test_inbound_email)
    mailbox.test_logger = logger
    mailbox.perform_processing

    expect(TestMailbox.last_context_result).to be true
  end

  it "should not raise an error when Rails.logger is nil" do
    Rails.logger = nil
    ActionMailbox.logger = logger

    mailbox = TestMailbox.new(create_test_inbound_email)
    mailbox.test_logger = logger
    mailbox.perform_processing

    expect(TestMailbox.last_context_result).to be true
  end

  it "should not raise an error when ActionMailbox logger is nil" do
    Rails.logger = logger  # This is what provides the context
    ActionMailbox.logger = nil

    mailbox = TestMailbox.new(create_test_inbound_email)
    mailbox.test_logger = logger
    mailbox.perform_processing

    expect(TestMailbox.last_context_result).to be true
  end
rescue LoadError
  skip "ActionMailbox is not available"
end
