# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails do
  describe "VERSION" do
    it "has a version number" do
      expect(Lumberjack::Rails::VERSION).not_to be nil
    end
  end
end
