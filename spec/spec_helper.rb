# frozen_string_literal: true

require "stringio"
require "rspec"

begin
  require "rails"
rescue LoadError
  # Stub Rails module for tests
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

      def env
        self.env ||= "test"
      end

      def env=(value)
        @env = ActiveSupport::StringInquirer.new(value)
      end
    end
  end
end

require_relative "../lib/lumberjack_rails"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
