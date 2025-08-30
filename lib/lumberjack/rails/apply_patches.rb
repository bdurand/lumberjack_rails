# frozen_string_literal: true

# Remove deprecated methods on Lumberjack::Logger that are implemented by ActiveSupport
Lumberjack::Logger.remove_method(:tagged) if Lumberjack::Logger.instance_methods.include?(:tagged)
Lumberjack::Logger.remove_method(:log_at) if Lumberjack::Logger.instance_methods.include?(:log_at)
Lumberjack::Logger.remove_method(:silence) if Lumberjack::Logger.instance_methods.include?(:silence)

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
Lumberjack::ForkedLogger.include(Lumberjack::Rails::TaggedForkedLogger)

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
