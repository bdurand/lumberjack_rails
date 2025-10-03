# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lumberjack::Rails::RackLoggerExtension do
  let(:rack_logger) { ::Rails::Rack::Logger.new(app) }
  let(:logger) { Lumberjack::Logger.new(:test) }
  let(:request) { {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/", "REMOTE_ADDR" => "127.0.0.1"} }
  let(:response) { [200, {"Content-Type" => "text/plain"}, ["OK"]] }
  let(:app) { ->(env) { response } }

  it "includes the 'Started ...' log message by default" do
    Lumberjack::Rails.silence_rack_request_started = false
    Rails.logger = logger
    rack_logger.call(request)
    expect(::Rails.logger.device).to include(severity: :info, message: /Started GET/)
  end

  it "can silence the 'Started ...' log message" do
    Lumberjack::Rails.silence_rack_request_started = true
    Rails.logger = logger
    rack_logger.call(request)
    expect(::Rails.logger.device).to_not include(message: /Started GET/)
  ensure
    Lumberjack::Rails.silence_rack_request_started = false
  end
end
