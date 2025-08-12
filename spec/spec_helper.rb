# frozen_string_literal: true

require "stringio"

require_relative "../lib/lumberjack_rails"

RSpec.configure do |config|
  config.warnings = true
  config.order = :random
end
