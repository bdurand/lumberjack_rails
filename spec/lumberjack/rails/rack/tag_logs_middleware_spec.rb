# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::Rack::TagLogsMiddleware do
  let(:app) do
    lambda do |env|
      [200, logger.attributes, ["OK"]]
    end
  end

  let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/test"} }

  let(:logger) { Lumberjack::Logger.new(:test) }

  it "adds attributes to loggers for the request" do
    middleware = Lumberjack::Rails::Rack::TagLogsMiddleware.new(app, ->(request) { {method: request.method} })
    response = middleware.call(env)

    expect(response).to eq([200, {"method" => "GET"}, ["OK"]])
  end

  it "does not add attributes if the logger_context_block does not return a hash" do
    middleware = Lumberjack::Rails::Rack::TagLogsMiddleware.new(app, ->(request) { "invalid" })
    response = middleware.call(env)

    expect(response).to eq([200, {}, ["OK"]])
  end
end
