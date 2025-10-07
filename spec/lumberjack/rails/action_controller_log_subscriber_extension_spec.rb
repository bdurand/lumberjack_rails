# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::ActionControllerLogSubscriberExtension do
  require "action_controller"

  let(:event) { ActiveSupport::Notifications::Event.new("test", Time.now.to_f, Time.now.to_f, {}, {}) }

  before :all do
    # Force framework to load before tests run.
    ActionController::Base
  end

  before do
    ActionController::LogSubscriber.send(:clear_process_log_attributes)
  end

  after do
    ActionController::LogSubscriber.send(:clear_process_log_attributes)
  end

  describe ".add_process_log_attribute" do
    it "adds a static log attribute" do
      ActionController::LogSubscriber.add_process_log_attribute(:user_id, 123)
      expect(ActionController::LogSubscriber.eval_process_log_attributes(event)).to eq({"user_id" => 123})
    end

    it "adds a dynamic log attribute that receives the event as an argument" do
      ActionController::LogSubscriber.add_process_log_attribute(:event) { |evt| evt.name }
      expect(ActionController::LogSubscriber.eval_process_log_attributes(event)).to eq({"event" => "test"})
    end

    it "adds a proc log attribute that receives the event as an argument" do
      ActionController::LogSubscriber.add_process_log_attribute(:timestamp, ->(evt) { evt.time.to_i })
      expect(ActionController::LogSubscriber.eval_process_log_attributes(event)).to eq({"timestamp" => event.time.to_i})
    end
  end

  describe ".process_log_attributes" do
    it "adds attributes from a block" do
      ActionController::LogSubscriber.process_log_attributes { |event| {event: event.name, status: "active"} }
      expect(ActionController::LogSubscriber.eval_process_log_attributes(event)).to eq({"event" => "test", "status" => "active"})
    end

    it "merges attributes from multiple blocks and individual attributes" do
      ActionController::LogSubscriber.add_process_log_attribute(:app, "my_app")
      ActionController::LogSubscriber.process_log_attributes { |event| {event: event.name} }
      ActionController::LogSubscriber.process_log_attributes { |event| {status: "active"} }
      expect(ActionController::LogSubscriber.eval_process_log_attributes(event)).to eq({"app" => "my_app", "event" => "test", "status" => "active"})
    end
  end

  describe "#process_action" do
    let(:subscriber) { ActionController::LogSubscriber.new }
    let(:logger) { Lumberjack::Logger.new(:test) }

    before do
      allow(subscriber).to receive(:logger).and_return(logger)
    end

    it "logs the message without any attributes when none are configured" do
      subscriber.process_action(event)
      log_entry = logger.device.entries.last
      expect(log_entry.message).to match(/Completed/)
      expect(log_entry.attributes).to be_nil
    end

    it "adds configured attributes to the log entry" do
      ActionController::LogSubscriber.add_process_log_attribute(:event_name) { |evt| evt.name }
      subscriber.process_action(event)
      log_entry = logger.device.entries.last
      expect(log_entry.message).to match(/Completed/)
      expect(log_entry.attributes).to eq({"event_name" => "test"})
    end
  end
end
