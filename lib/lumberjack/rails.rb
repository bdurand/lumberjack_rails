# frozen_string_literal: true

require "lumberjack"
require "active_support"

# Lumberjack is a logging framework for Ruby applications.
# This gem extends Lumberjack with Rails-specific functionality.
module Lumberjack
  # Rails integration for Lumberjack logger.
  #
  # This module provides integration between Lumberjack and Rails applications,
  # enhancing Rails' logging capabilities while maintaining compatibility with
  # existing Rails logging patterns.
  module Rails
    class << self
      # Safely wrap Rails.logger with a Lumberjack context.
      #
      # @param additional_logger [Logger] an optional additional logger to wrap with a context.
      # @yield [Logger] the block to execute with the wrapped logger context.
      # @return [Object] the result of the block execution.
      def logger_context(additional_logger = nil, &block)
        rails_logger = ::Rails.logger
        Lumberjack.context do
          if additional_logger && rails_logger != additional_logger
            wrap_block_with_logger_context(rails_logger) do
              wrap_block_with_logger_context(additional_logger, &block)
            end
          else
            wrap_block_with_logger_context(rails_logger, &block)
          end
        end
      end

      private

      # Wrap a block with a logger context if the logger supports it.
      #
      # @param logger [Logger] the logger to wrap
      # @yield the block to execute within the logger context
      # @return [Object] the result of the block execution
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

require_relative "rails/action_cable_extension"
require_relative "rails/action_controller_extension"
require_relative "rails/action_mailbox_extension"
require_relative "rails/action_mailer_extension"
require_relative "rails/active_job_extension"
require_relative "rails/broadcast_logger_extension"
require_relative "rails/log_at_level"
require_relative "rails/middleware"
require_relative "rails/tagged_forked_logger"
require_relative "rails/tagged_logging_formatter"

# Remove deprecated methods on Lumberjack::Logger that are implemented by ActiveSupport
Lumberjack::Logger.remove_method(:tagged) if Lumberjack::Logger.instance_methods.include?(:tagged)
Lumberjack::Logger.remove_method(:log_at) if Lumberjack::Logger.instance_methods.include?(:log_at)
Lumberjack::Logger.remove_method(:silence) if Lumberjack::Logger.instance_methods.include?(:silence)

# Add tagged logging support to the Lumberjack::EntryFormatter
# @!visibility private
Lumberjack::EntryFormatter.prepend(Lumberjack::Rails::TaggedLoggingFormatter)
# @!visibility private
Lumberjack::EntryFormatter.include(ActiveSupport::TaggedLogging::Formatter)

# Add silence method to Lumberjack::Logger
require "active_support/logger_silence"
# @!visibility private
Lumberjack::ContextLogger.include(ActiveSupport::LoggerSilence)

# Use prepend to ensure level is overridden properly
# @!visibility private
Lumberjack::ContextLogger.prepend(Lumberjack::Rails::LogAtLevel)

# Add tagged logging support to Lumberjack
# @!visibility private
Lumberjack::ContextLogger.prepend(ActiveSupport::TaggedLogging)
# @!visibility private
Lumberjack::ForkedLogger.include(Lumberjack::Rails::TaggedForkedLogger)

# @!visibility private
ActiveSupport::BroadcastLogger.prepend(Lumberjack::Rails::BroadcastLoggerExtension)

ActiveSupport.on_load(:active_job) do
  ActiveJob::Base.prepend(Lumberjack::Rails::ActiveJobExtension)
end

ActiveSupport.on_load(:action_cable) do
  ActionCable::Connection::Base.prepend(Lumberjack::Rails::ActionCableExtension)
end

ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.prepend(Lumberjack::Rails::ActionMailerExtension)
end

ActiveSupport.on_load(:action_mailbox) do
  ActionMailbox::Base.prepend(Lumberjack::Rails::ActionMailboxExtension)
end

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.prepend(Lumberjack::Rails::ActionControllerExtension)
end

if defined?(Rails::Railtie)
  require_relative "rails/railtie"
end
