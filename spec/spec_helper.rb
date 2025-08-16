# frozen_string_literal: true

require "stringio"

require_relative "../lib/lumberjack_rails"

# Mock out Rails.logger for tests
module Rails
  @logger = nil

  class << self
    attr_reader :logger

    def logger=(logger)
      @logger = if logger.is_a?(ActiveSupport::BroadcastLogger)
        logger
      else
        ActiveSupport::BroadcastLogger.new(logger)
      end
    end
  end
end

RSpec.configure do |config|
  config.order = :random
end
