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

require_relative "rails/action_cable_context"
require_relative "rails/active_job_context"
require_relative "rails/broadcast_logger_extension"
require_relative "rails/rack/request_id_middleware"
require_relative "rails/tagged_local_logger"
require_relative "rails/tagged_logger"
require_relative "rails/tagged_logging_formatter"

# Add tagged logging support to the Lumberjack::EntryFormatter
Lumberjack::EntryFormatter.prepend(Lumberjack::Rails::TaggedLoggingFormatter)
Lumberjack::EntryFormatter.include(ActiveSupport::TaggedLogging::Formatter)

# Add silence method to Lumberjack::Logger
require "active_support/logger_silence"
Lumberjack::ContextLogger.include(ActiveSupport::LoggerSilence)

# Use prepend to ensure level is overridden properly
Lumberjack::ContextLogger.prepend(Lumberjack::Rails::LogAtLevel)

# Add tagged logging support to Lumberjack
Lumberjack::ContextLogger.prepend(ActiveSupport::TaggedLogging)
Lumberjack::Logger.prepend(Lumberjack::Rails::TaggedLogger)
Lumberjack::LocalLogger.include(Lumberjack::Rails::TaggedLocalLogger)

ActiveSupport::BroadcastLogger.prepend(Lumberjack::Rails::BroadcastLoggerExtension)

if defined?(Rails::Railtie)
  require_relative "rails/railtie"
end
