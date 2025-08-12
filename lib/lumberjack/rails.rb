# frozen_string_literal: true

require "lumberjack"
require "active_support"

module Lumberjack::Rails
  # This module is needed to prepend the local_level behavior onto Lumberjack::Logger.
  module LogAtLevel
    def level
      local_level || super
    end
  end
end

require_relative "rails/tagged_logging_formatter"

# Add tagged logging support to the Lumberjack::EntryFormatter
Lumberjack::EntryFormatter.prepend(Lumberjack::Rails::TaggedLoggingFormatter)

# Add silence method to Lumberjack::Logger
require "active_support/logger_silence"
Lumberjack::Logger.include(ActiveSupport::LoggerSilence)

# Use prepend to ensure level is overridden properly
Lumberjack::Logger.prepend(Lumberjack::Rails::LogAtLevel)

if defined?(Rails::Railtie)
  require_relative "rails/railtie"
end
