# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::LogSubscriberExtension do
  let(:log_subscriber) do
    Class.new(ActiveSupport::LogSubscriber) do
      prepend Lumberjack::Rails::LogSubscriberExtension
    end
  end

  around do |example|
    Rails.logger = Lumberjack::Logger.new(:test)
    example.run
    Rails.logger = nil
  end

  describe "#logger" do
    it "returns a memoized fork of the Rails.logger by default" do
      logger = log_subscriber.logger
      expect(logger).to be_a(Lumberjack::ForkedLogger)
      expect(logger.parent_logger).to eq(Rails.logger)
      expect(logger).to equal(log_subscriber.logger)
    end

    it "can use a different logger" do
      custom_logger = Lumberjack::Logger.new(:test)
      log_subscriber.logger = custom_logger
      expect(log_subscriber.logger.parent_logger).to eq(custom_logger)
    end

    it "returns Rails.logger if logger is set to nil" do
      expect(log_subscriber.logger).to_not be_nil
      log_subscriber.logger = nil
      expect(log_subscriber.logger.parent_logger).to eq(Rails.logger)
    end

    it "can fetch the logger with a proc at runtime" do
      logger = nil
      log_subscriber.logger = -> { logger }
      expect(log_subscriber.logger).to be_nil
      logger = Lumberjack::Logger.new(:test)
      expect(log_subscriber.logger.parent_logger).to eq(logger)
    end

    it "does not fork the logger if it is not a Lumberjack logger" do
      logger = Logger.new(StringIO.new)
      log_subscriber.logger = logger
      expect(log_subscriber.logger).to eq(logger)
    end

    it "create a new fork if the logger is changed" do
      original_logger = log_subscriber.logger
      new_logger = Lumberjack::Logger.new(:test)
      log_subscriber.logger = new_logger
      expect(log_subscriber.logger).to_not eq(original_logger)
      expect(log_subscriber.logger.parent_logger).to eq(new_logger)
    end

    it "can change the logger from a Lumberjack logger to a standard logger" do
      original_logger = log_subscriber.logger
      new_logger = Logger.new(StringIO.new)
      log_subscriber.logger = new_logger
      expect(log_subscriber.logger).to eq(new_logger)
    end

    it "can change the logger from a standard logger to a Lumberjack logger" do
      log_subscriber.logger = Logger.new(StringIO.new)
      original_logger = log_subscriber.logger
      new_logger = Lumberjack::Logger.new(:test)
      log_subscriber.logger = new_logger
      expect(log_subscriber.logger).to_not eq(original_logger)
      expect(log_subscriber.logger.parent_logger).to eq(new_logger)
    end
  end

  describe "ActiveJob::LogSubscriber" do
    require "active_job"

    around do |example|
      save_logger = ActiveJob::Base.logger
      ActiveJob::Base.logger = Lumberjack::Logger.new(:test)
      example.run
      ActiveJob::Base.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActiveJob::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActiveJob::Base.logger by default" do
      expect(ActiveJob::LogSubscriber.logger.parent_logger).to eq(ActiveJob::Base.logger)
    end
  end

  describe "ActionMailer::LogSubscriber" do
    require "action_mailer"

    around do |example|
      save_logger = ActionMailer::Base.logger
      ActionMailer::Base.logger = Lumberjack::Logger.new(:test)
      example.run
      ActionMailer::Base.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActionMailer::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActionMailer::Base.logger by default" do
      expect(ActionMailer::LogSubscriber.logger.parent_logger).to eq(ActionMailer::Base.logger)
    end
  end

  describe "ActionController::LogSubscriber" do
    require "action_controller"

    around do |example|
      save_logger = ActionController::Base.logger
      ActionController::Base.logger = Lumberjack::Logger.new(:test)
      example.run
      ActionController::Base.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActionController::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActionController::Base.logger by default" do
      expect(ActionController::LogSubscriber.logger.parent_logger).to eq(ActionController::Base.logger)
    end
  end

  describe "ActionDispatch::LogSubscriber" do
    require "action_dispatch"

    around do |example|
      save_logger = Rails.logger
      Rails.logger = Lumberjack::Logger.new(:test)
      example.run
      Rails.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActionDispatch::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActionDispatch::LogSubscriber.logger by default" do
      expect(ActionDispatch::LogSubscriber.logger.parent_logger).to eq(Rails.logger)
    end
  end

  describe "ActionView::LogSubscriber" do
    require "action_view"

    around do |example|
      save_logger = ActionView::Base.logger
      ActionView::Base.logger = Lumberjack::Logger.new(:test)
      example.run
      ActionView::Base.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActionView::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActionView::Base.logger by default" do
      expect(ActionView::LogSubscriber.logger.parent_logger).to eq(ActionView::Base.logger)
    end
  end

  describe "ActiveRecord::LogSubscriber" do
    require "active_record"

    around do |example|
      save_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = Lumberjack::Logger.new(:test)
      example.run
      ActiveRecord::Base.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActiveRecord::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActiveRecord::Base.logger by default" do
      expect(ActiveRecord::LogSubscriber.logger.parent_logger).to eq(ActiveRecord::Base.logger)
    end
  end

  describe "ActiveStorage::LogSubscriber" do
    require "active_storage"
    require "active_storage/log_subscriber"

    before :all do
      ActiveSupport.run_load_hooks :active_storage_record, self
    end

    around do |example|
      save_logger = ActiveStorage.logger
      ActiveStorage.logger = Lumberjack::Logger.new(:test)
      example.run
      ActiveStorage.logger = save_logger
    end

    it "includes Lumberjack::Rails::LogSubscriberExtension" do
      expect(ActiveStorage::LogSubscriber).to include(Lumberjack::Rails::LogSubscriberExtension)
    end

    it "uses the ActiveStorage::LogSubscriber.logger by default" do
      expect(ActiveStorage::LogSubscriber.logger.parent_logger).to eq(ActiveStorage.logger)
    end
  end
end
