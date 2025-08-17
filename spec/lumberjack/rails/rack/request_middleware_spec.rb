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

  it "logs the request" do
    logger = Lumberjack::Logger.new(:test)
    Rails.logger = logger

    logger_handler = lambda do |request|
      Rails.logger.tag(foo: "bar")
    end

    middleware = Lumberjack::Rails::Rack::RequestMiddleware.new(app, logger_handler)

    response = middleware.call(env)
    expect(response).to eq([200, {}, ["OK"]])
    expect(logger.device).to include(severity: :info, message: "test", tags: {foo: "bar"})
  end
end
