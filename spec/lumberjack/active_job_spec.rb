# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "ActiveJob integration" do
  require "active_job"

  # Test job classes
  class TestJob < ActiveJob::Base
    def perform(lumberjack_logger)
      lumberjack_logger.context?
    end
  end

  let(:logger) { Lumberjack::Logger.new(:test) }
  let(:standard_logger) { ::Logger.new(File::NULL) }

  before(:all) do
    ActiveJob::Base.queue_adapter = :inline
  end

  after do
    Rails.logger = nil
    ActiveJob::Base.logger = nil
  end

  it "should add a context block to the Rails logger" do
    Rails.logger = logger
    ActiveJob::Base.logger = standard_logger
    expect(TestJob.perform_now(logger)).to be true
  end

  it "should add a context block to the ActiveJob logger" do
    Rails.logger = standard_logger
    ActiveJob::Base.logger = logger
    expect(TestJob.perform_now(logger)).to be true
  end

  it "should not raise an error when Rails.logger is nil" do
    Rails.logger = nil
    ActiveJob::Base.logger = logger
    expect(TestJob.perform_now(logger)).to be true
  end

  it "should not raise an error when ActiveJob logger is nil" do
    Rails.logger = logger
    ActiveJob::Base.logger = nil
    expect(TestJob.perform_now(logger)).to be true
  end
rescue LoadError
  skip "ActiveJob is not available"
end
