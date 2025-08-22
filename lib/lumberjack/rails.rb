# frozen_string_literal: true

require "lumberjack"
require "active_support"

module Lumberjack
  module Rails
    class << self
      # Safely wrap Rails.logger with a Lumberjack context.
      #
      # @param additional_logger [Logger] an optional additional logger to wrap with a context.
      # @yield [Logger] the block to execute with the wrapped logger context.
      # @return [Object] the result of the block execution.
      def logger_context(additional_logger = nil, &block)
        rails_logger = ::Rails.logger
        if additional_logger && rails_logger != additional_logger
          wrap_block_with_logger_context(rails_logger) do
            wrap_block_with_logger_context(additional_logger, &block)
          end
        else
          wrap_block_with_logger_context(rails_logger, &block)
        end
      end

      private

      def wrap_block_with_logger_context(logger, &block)
        if logger&.respond_to?(:context)
          logger.context(&block)
        else
          block.call
        end
      end
    end
  end
end

require_relative "rails/broadcast_logger_extension"
require_relative "rails/log_at_level"
require_relative "rails/rack/context_middleware"
require_relative "rails/rack/tag_logs_middleware"
require_relative "rails/tagged_forked_logger"
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
Lumberjack::ForkedLogger.include(Lumberjack::Rails::TaggedForkedLogger)

ActiveSupport::BroadcastLogger.prepend(Lumberjack::Rails::BroadcastLoggerExtension)

ActiveSupport.on_load(:active_job) do
  ActiveJob::Base.around_perform { |_job, block| Lumberjack::Rails.logger_context(logger, &block) }
end

ActiveSupport.on_load(:action_cable) do
  ActionCable::Connection::Base.around_command { |_command, block| Lumberjack::Rails.logger_context(logger, &block) }
end

ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.around_action { |_mail, block| Lumberjack::Rails.logger_context(logger, &block) }
end

ActiveSupport.on_load(:action_mailbox) do
  ActionMailbox::Base.around_processing { |_mail, block| Lumberjack::Rails.logger_context(logger, &block) }
end

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.around_action { |_controller, block| Lumberjack::Rails.logger_context(logger, &block) }
end

if defined?(Rails::Railtie)
  require_relative "rails/railtie"
end
