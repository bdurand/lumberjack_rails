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

    prepended do
      @__logger ||= nil
      @__silenced_events ||= nil
    end

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

        if class_logger.respond_to?(:fork)
          if !@__logger.is_a?(Lumberjack::ForkedLogger) || @__logger&.parent_logger != class_logger
            @__logger = class_logger.fork
          end
        else
          @__logger = class_logger
        end

        @__logger
      end

      # Silence an individual event for this subscriber. The event name is the name of the public
      # instance method to silence.
      #
      # @param event_name [String, Symbol] the name of the event to silence
      # @return [void]
      def silence_event!(event_name)
        @__silenced_events ||= Set.new
        @__silenced_events << event_name.to_s
      end

      # Unsilence an individual event for this subscriber.
      #
      # @param event_name [String, Symbol] the name of the event to unsilence
      # @return [void]
      def unsilence_event!(event_name)
        @__silenced_events&.delete(event_name.to_s)
      end

      # Check if a specific event is silenced for this subscriber.
      #
      # @param event [String] the full event name of the event to check with the namespace
      # @return [Boolean] true if the event is silenced, false otherwise
      # @api private
      def silenced_event?(event)
        return false if @__silenced_events.nil?

        i = event.index(".")
        event_name = i ? event[0, i] : event
        @__silenced_events.include?(event_name)
      end
    end

    # Override the silenced? method to check if the event has been explicitly silenced.
    #
    # @param event [String] the event to check
    # @return [Boolean] true if the event is silenced, false otherwise
    def silenced?(event)
      super || self.class.silenced_event?(event)
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
