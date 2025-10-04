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
end
