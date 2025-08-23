# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::Middleware do
  let(:app) do
    lambda do |env|
      [200, logger.attributes, ["OK"]]
    end
  end

  let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/test"} }

  let(:logger) { Lumberjack::Logger.new(:test) }

  before do
    Rails.logger = logger
  end

  it "adds attributes to loggers for the request" do
    middleware = Lumberjack::Rails::Middleware.new(app, ->(request) { {method: request.method} })
    response = middleware.call(env)

    expect(response).to eq([200, {"method" => "GET"}, ["OK"]])
  end

  it "does not add attributes if the logger_context_block does not return a hash" do
    middleware = Lumberjack::Rails::Middleware.new(app, ->(request) { "invalid" })
    response = middleware.call(env)

    expect(response).to eq([200, {}, ["OK"]])
  end

  it "works without adding any attributes" do
    middleware = Lumberjack::Rails::Middleware.new(app)
    response = middleware.call(env)

    expect(response).to eq([200, {}, ["OK"]])
  end
end
