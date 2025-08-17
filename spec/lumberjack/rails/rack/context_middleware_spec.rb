# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Lumberjack::Rails::Rack::ContextMiddleware do
  let(:logger) { Lumberjack::Logger.new(:test) }

  let(:app) do
    lambda { |env| [200, {context: logger.context?}, ["OK"]] }
  end

  let(:env) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/test"} }

  it "adds a context to Rails.logger" do
    Rails.logger = logger
    middleware = Lumberjack::Rails::Rack::ContextMiddleware.new(app)
    response = middleware.call(env)

    expect(response).to eq([200, {context: true}, ["OK"]])
  end

  begin
    require "action_controller"

    before do
      ActionController::Base.logger = logger
    end

    after do
      ActionController::Base.logger = nil
    end

    it "adds a context to ActionController logger" do
      Rails.logger = nil
      middleware = Lumberjack::Rails::Rack::ContextMiddleware.new(app)
      response = middleware.call(env)

      expect(response).to eq([200, {context: true}, ["OK"]])
    end

    it "adds a context to both Rails and ActionController logger" do
      Rails.logger = Lumberjack::Logger.new(:test)
      app = lambda { |env| [200, {rails: Rails.logger.context?, controller: logger.context?}, ["OK"]] }
      middleware = Lumberjack::Rails::Rack::ContextMiddleware.new(app)
      response = middleware.call(env)

      expect(response).to eq([200, {rails: true, controller: true}, ["OK"]])
    end
  rescue LoadError
    skip "ActionController is not available"
  end
end
