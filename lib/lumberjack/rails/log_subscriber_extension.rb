# frozen_string_literal: true

module Lumberjack::Rails
  # Extension for Rails log subscribers to provide Lumberjack logger integration.
  #
  # This module enables Rails log subscribers (such as ActiveRecord::LogSubscriber,
  # ActionController::LogSubscriber, etc.) to use forked Lumberjack loggers.
  # Forked loggers provide isolation, allowing different log levels and attributes
  # to be set for different log subscribers without affecting the main logger.
  #
  # When a log subscriber's logger is accessed, this extension checks if the
  # parent logger supports forking. If it does, a ForkedLogger is created and
  # cached for subsequent use. This ensures each log subscriber has its own
  # isolated logger context.
  module LogSubscriberExtension
    extend ActiveSupport::Concern

    class_methods do
      # Get the logger for this log subscriber class.
      #
      # This method overrides the default Rails log subscriber logger behavior
      # to provide Lumberjack forked logger support. If the parent logger supports
      # forking, a ForkedLogger is created and cached. Otherwise, the original
      # logger is returned unchanged.
      #
      # @return [Lumberjack::ForkedLogger, Logger] the logger instance for this subscriber
      def logger
        class_logger = super
        class_logger = class_logger.call if class_logger.is_a?(Proc)

        @__logger ||= nil

        if class_logger.respond_to?(:fork)
          if !@__logger.is_a?(Lumberjack::ForkedLogger) || @__logger&.parent_logger != class_logger
            @__logger = class_logger.fork
          end
        else
          @__logger = class_logger
        end

        @__logger
      end
    end

    # Get the logger for this log subscriber instance.
    #
    # Delegates to the class-level logger method to ensure consistent
    # behavior across all instances of the log subscriber.
    #
    # @return [Lumberjack::ForkedLogger, Logger] the logger instance for this subscriber
    def logger
      self.class.logger
    end
  end
end
