# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::Middleware do
  let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/test"} }

  let(:logger) { Lumberjack::Logger.new(:test) }

  before do
    Rails.logger = logger
  end

  it "adds context to Rails.logger" do
    app = lambda do |env|
      [200, {"in-context" => Rails.logger.in_context?}, ["OK"]]
    end

    middleware = Lumberjack::Rails::Middleware.new(app)
    response = middleware.call(env)

    expect(response).to eq([200, {"in-context" => true}, ["OK"]])
  end

  it "adds a global Lumberjack context" do
    app = lambda do |env|
      [200, {"in-context" => Lumberjack.in_context?}, ["OK"]]
    end

    middleware = Lumberjack::Rails::Middleware.new(app)
    response = middleware.call(env)

    expect(response).to eq([200, {"in-context" => true}, ["OK"]])
  end
end
