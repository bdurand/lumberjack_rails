# frozen_string_literal: true

# Integration patches for Lumberjack Rails support.
#
# This file applies various patches and extensions to integrate Lumberjack
# with Rails framework components. It performs the following key integrations:
#
# 1. Removes deprecated Lumberjack::Logger methods that conflict with ActiveSupport
# 2. Adds tagged logging support to Lumberjack formatters and loggers
# 3. Extends ActiveSupport::BroadcastLogger with Lumberjack compatibility
# 4. Integrates with Rails framework components (ActiveJob, ActionCable, etc.)
# 5. Sets up log subscribers to use forked Lumberjack loggers
#
# These patches ensure seamless integration between Lumberjack's logging
# capabilities and Rails' existing logging infrastructure while maintaining
# backward compatibility with existing Rails logging patterns.

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

# Add hook to allow disabling of "Started ..." log lines in Rack::Logger
::Rails::Rack::Logger.prepend(Lumberjack::Rails::RackLoggerExtension)

ActiveSupport.on_load(:active_job) do
  ActiveJob::Base.prepend(Lumberjack::Rails::ActiveJobExtension)
  ActiveJob::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
  ActiveJob::LogSubscriber.logger = -> { ActiveJob::Base.logger }
end

ActiveSupport.on_load(:action_cable) do
  ActionCable::Connection::Base.prepend(Lumberjack::Rails::ActionCableExtension)
end

ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.prepend(Lumberjack::Rails::ActionMailerExtension)
  ActionMailer::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
  ActionMailer::LogSubscriber.logger = -> { ActionMailer::Base.logger }
end

ActiveSupport.on_load(:action_mailbox) do
  ActionMailbox::Base.prepend(Lumberjack::Rails::ActionMailboxExtension)
end

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.prepend(Lumberjack::Rails::ActionControllerExtension)

  ActionController::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
  ActionController::LogSubscriber.logger = -> { ActionController::Base.logger }

  ActionDispatch::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
end

ActiveSupport.on_load(:action_view) do
  ActionView::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
  ActionView::LogSubscriber.logger = -> { ActionView::Base.logger }
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
  ActiveRecord::LogSubscriber.logger = -> { ActiveRecord::Base.logger }
end

ActiveSupport.on_load(:active_storage_record) do
  ActiveStorage::LogSubscriber.prepend(Lumberjack::Rails::LogSubscriberExtension)
  ActiveStorage::LogSubscriber.logger = -> { ActiveStorage.logger }
end
