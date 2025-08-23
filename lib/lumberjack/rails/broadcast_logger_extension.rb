# frozen_string_literal: true

module Lumberjack
  module Rails
    module BroadcastLoggerExtension
      def initialize(*loggers)
        if loggers.count { |logger| logger.is_a?(Lumberjack::ContextLogger) } > 1
          raise ArgumentError, "Only one Lumberjack logger is allowed"
        end

        super
      end

      def debug(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :debug, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      def info(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :info, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      def warn(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :warn, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      def error(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :error, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      def fatal(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :fatal, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      def unknown(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :unknown, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Override the with_level method defined on the logger gem to use Rails' log_at method instead.
      def with_level(level, &block)
        log_at(level, &block)
      end

      def tag(attributes, &block)
        if block
          dispatch_block_method(:tag, attributes, &block)
        else
          dispatch do |logger|
            logger.tag(attributes)
          end
        end
      end

      def context(&block)
        dispatch_block_method(:context, &block)
      end

      def untagged(&block)
        dispatch_block_method(:untagged, &block)
      end

      def with_progname(value, &block)
        dispatch_block_method(:with_progname, value, &block)
      end

      def fork(level: nil, progname: nil, attributes: nil)
        logger = Lumberjack::ForkedLogger.new(self)
        logger.level = level if level
        logger.progname = progname if progname
        logger.tag!(attributes) if attributes && !attributes.empty?
        logger
      end

      private

      # Lumberjack loggers support an optional attributes argument to the logging methods. This method provides
      # compatibility with other Loggers that don't support that argument. The arguments here are funky because
      # the methods on Logger are funky. On Logger the sole argument to a logging method can be message or
      # the progname depending on if the message is in the block.
      def call_with_attributes_arg(logger, method, message_or_progname_or_attributes, progname_or_attributes, &block)
        if logger.is_a?(Lumberjack::ContextLogger)
          logger.send(method, message_or_progname_or_attributes, progname_or_attributes, &block)
        elsif block
          progname = message_or_progname_or_attributes unless progname_or_attributes.is_a?(Hash)
          logger.send(method, progname, &block)
        else
          logger.send(method, message_or_progname_or_attributes)
        end
      end

      # Guard against multiple loggers responding to the same method that takes
      # a block. In that case we don't want to call the block multiple times.
      # This does not include the logging methods like `info` but does include
      # methods like `tag` that are expected to be called with a block that
      # has business logic inside of it.
      def dispatch_block_method(name, ...)
        loggers = broadcasts.select { |logger| logger.respond_to?(name) }

        return yield if loggers.none?
        return loggers.first.send(name, ...) if loggers.one?

        message = "BroadcastLogger cannot call #{name} on multiple loggers with a block."
        loggers.first.warn("#{message} It was called on this logger.")
        loggers[1..].each { |logger| logger.warn("#{message} It was not called on this logger.") }
        loggers.first.send(name, ...)
      end
    end
  end
end
