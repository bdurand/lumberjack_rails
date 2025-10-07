# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails do
  describe "VERSION" do
    it "has a version number" do
      expect(Lumberjack::Rails::VERSION).not_to be nil
    end
  end

  describe ".silence_rack_request_started?" do
    it "defaults to false" do
      expect(Lumberjack::Rails.silence_rack_request_started?).to be false
    end

    it "can be set to true" do
      save_val = Lumberjack::Rails.silence_rack_request_started?
      begin
        Lumberjack::Rails.silence_rack_request_started = true
        expect(Lumberjack::Rails.silence_rack_request_started?).to be true
      ensure
        Lumberjack::Rails.silence_rack_request_started = save_val
      end
    end
  end

  describe ".active_record_entry_formatter" do
    let(:formatter) { Lumberjack::Rails.active_record_entry_formatter }

    let(:mock_active_record_base) do
      Class.new do
        def self.name
          "ActiveRecord::Base"
        end
      end
    end

    let(:mock_active_record_class) do
      Class.new do
        attr_accessor :id

        def self.name
          "AppModel"
        end
      end
    end

    let(:record) { mock_active_record_class.new }

    before do
      allow(mock_active_record_class).to receive(:ancestors).and_return([mock_active_record_class, mock_active_record_base])
    end

    it "formats a model in the message as ModelName.id" do
      record.id = 123
      message, _ = formatter.format(record, {})
      expect(message).to eq("AppModel.123")
    end

    it "formats a new record in the message as ModelName.new_record" do
      record.id = nil
      message, _ = formatter.format(record, {})
      expect(message).to eq("AppModel.new_record")
    end

    it "formats a model in an attribute as a hash with class and id" do
      record.id = 123
      _, attributes = formatter.format("Test", {model: record})
      expect(attributes).to eq({"model" => {"class" => "AppModel", "id" => 123}})
    end
  end
end
