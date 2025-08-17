# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "Railtie" do
  require "rails"

  let(:app) { double(config: config, paths: paths, env: )
    Class.new(Rails::Application) do
      config.eager_load = false
    end
  }
  let(:config) { ActiveSupport::OrderedOptions.new }
  let(:paths) { Rails::Paths::Root.new }

  describe "logger configuration" do
  end
rescue LoadError
  skip "Rails is not available"
end
