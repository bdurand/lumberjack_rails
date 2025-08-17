# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Lumberjack::Rails::Rack::RequestMiddleware do
  let(:app) do
    lambda do |env|
      Rails.logger&.info("test")
      [200, {}, ["OK"]]
    end
  end

  let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/test"} }

  it "adds a context to Rails.logger"

  begin
    require "action_controller"

    it "adds a context to ActionController logger"
  rescue LoadError
    skip "ActionController is not available"
  end
end
