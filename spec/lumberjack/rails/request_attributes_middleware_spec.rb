# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::RequestAttributesMiddleware do
  let(:app) do
    lambda { |env| [200, Rails.logger&.attributes || {}, ["OK"]] }
  end

  let(:env) do
    {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/test",
      "rack.input" => StringIO.new,
      "action_dispatch.request_id" => "12345"
    }
  end

  before do
    Rails.logger = Lumberjack::Logger.new(:test)
  end

  it "adds attributes from the request to the logger context" do
    attributes_block = lambda do |request|
      {
        method: request.request_method,
        path: request.path
      }
    end
    middleware = Lumberjack::Rails::RequestAttributesMiddleware.new(app, attributes_block)
    _status, headers, _body = middleware.call(env)

    expect(headers).to eq("method" => "GET", "path" => "/test")
  end

  it "does nothing if the attributes block returns nil" do
    attributes_block = lambda { |request| }
    middleware = Lumberjack::Rails::RequestAttributesMiddleware.new(app, attributes_block)
    _status, headers, _body = middleware.call(env)

    expect(headers).to eq({})
  end

  it "does nothing if Rails.logger is nil" do
    Rails.logger = nil
    attributes_block = lambda do |request|
      {
        method: request.request_method,
        path: request.path
      }
    end
    middleware = Lumberjack::Rails::RequestAttributesMiddleware.new(app, attributes_block)
    _status, headers, _body = middleware.call(env)

    expect(headers).to eq({})
  end
end
