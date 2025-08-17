# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Lumberjack::Rails::Rack::RequestMiddleware do
  let(:app) do
    lambda do |env|
      [200, logger.tags, ["OK"]]
    end
  end

  let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/test"} }

  let(:logger) { Lumberjack::Logger.new(:test) }

  it "adds tags to loggers for the request" do
    middleware = Lumberjack::Rails::Rack::RequestMiddleware.new(app, ->(request) { {method: request.method} })
    response = middleware.call(env)

    expect(response).to eq([200, {"method" => "GET"}, ["OK"]])
  end

  it "does not add tags if the logger_context_block does not return a hash" do
    middleware = Lumberjack::Rails::Rack::RequestMiddleware.new(app, ->(request) { "invalid" })
    response = middleware.call(env)

    expect(response).to eq([200, {}, ["OK"]])
  end
end
