# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for ActiveSupport::BroadcastLogger to provide Lumberjack compatibility.
    #
    # This module extends ActiveSupport::BroadcastLogger to ensure proper handling
    # of Lumberjack loggers when broadcasting to multiple loggers, including
    # support for Lumberjack-specific features like attributes and contexts.
    module BroadcastLoggerExtension
      # Initialize the broadcast logger with validation for Lumberjack loggers.
      #
      # @param loggers [Array<Logger>] array of loggers to broadcast to
      # @raise [ArgumentError] if more than one Lumberjack logger is provided
      def initialize(*loggers)
        if loggers.count { |logger| logger.is_a?(Lumberjack::ContextLogger) } > 1
          raise ArgumentError, "Only one Lumberjack logger is allowed"
        end

        super
      end

      # Log a debug message with optional attributes support.
      #
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def debug(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :debug, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Log an info message with optional attributes support.
      #
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def info(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :info, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Log a warning message with optional attributes support.
      #
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def warn(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :warn, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Log an error message with optional attributes support.
      #
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def error(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :error, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Log a fatal message with optional attributes support.
      #
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def fatal(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :fatal, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Log an unknown severity message with optional attributes support.
      #
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def unknown(message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        dispatch do |logger|
          call_with_attributes_arg(logger, :unknown, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      # Add a log entry with the specified severity and optional attributes support.
      #
      # @param severity [Integer, Symbol, String] the severity for the log entry
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def add(severity, message_or_progname_or_attributes = nil, progname_or_attributes = nil, &block)
        severity = Logger::Severity.coerce(severity)
        dispatch do |logger|
          call_add_with_attributes_arg(logger, severity, message_or_progname_or_attributes, progname_or_attributes, &block)
        end
      end

      alias_method :log, :add

      # Override the with_level method defined on the logger gem to use Rails' log_at method instead.
      #
      # @param level [Symbol, Integer] the log level to set temporarily
      # @yield the block to execute at the specified log level
      # @return [Object] the result of the block execution
      def with_level(level, &block)
        log_at(level, &block)
      end

      # Tag log entries with the specified attributes.
      #
      # @param attributes [Hash] the attributes to tag with
      # @yield the block to execute with the tagged context
      # @return [Object] the result of the block execution
      def tag(attributes, &block)
        dispatch_block_method(:tag, attributes, &block)
      end

      # Execute a block within a logger context.
      #
      # @yield the block to execute within the context
      # @return [Object] the result of the block execution
      def context(&block)
        dispatch_block_method(:context, &block)
      end

      # Append values to an existing attribute.
      #
      # @param attribute_name [String, Symbol] the name of the attribute
      # @param tag [Array] the values to append
      # @yield the block to execute with the modified attribute
      # @return [Object] the result of the block execution
      def append_to(attribute_name, *tag, &block)
        dispatch_block_method(:append_to, attribute_name, *tag, &block)
      end

      # Clear all current attributes.
      #
      # @yield the block to execute with cleared attributes
      # @return [Object] the result of the block execution
      def clear_attributes(&block)
        dispatch_block_method(:clear_attributes, &block)
      end

      # Execute a block without any tags.
      #
      # @yield the block to execute without tags
      # @return [Object] the result of the block execution
      def untagged(&block)
        dispatch_block_method(:untagged, &block)
      end

      # Set the progname temporarily for a block.
      #
      # @param value [String] the progname to set
      # @yield the block to execute with the specified progname
      # @return [Object] the result of the block execution
      def with_progname(value, &block)
        dispatch_block_method(:with_progname, value, &block)
      end

      # Alias for with_progname for backward compatibility.
      #
      # @param value [String] the progname to set
      # @yield the block to execute with the specified progname
      # @return [Object] the result of the block execution
      def set_progname(value, &block)
        dispatch_block_method(:with_progname, value, &block)
      end

      # Create a forked logger from this broadcast logger.
      #
      # @param level [Symbol, Integer] optional log level for the forked logger
      # @param progname [String] optional progname for the forked logger
      # @param attributes [Hash] optional attributes for the forked logger
      # @return [Lumberjack::ForkedLogger] the forked logger
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
      #
      # @param logger [Logger] the logger to call the method on
      # @param method [Symbol] the logging method to call
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
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

      # Lumberjack loggers support an optional attributes argument to the logging methods. This method provides
      # compatibility with other Loggers that don't support that argument. The arguments here are funky because
      # the methods on Logger#add are funky. On Logger the sole argument to a logging method can be message or
      # the progname depending on if the message is in the block.
      #
      # @param logger [Logger] the logger to call the method on
      # @param severity [Integer, Symbol, String] the severity for the log entry
      # @param message_or_progname_or_attributes [String, Hash] the message, progname, or attributes
      # @param progname_or_attributes [String, Hash] the progname or attributes
      # @yield optional block that returns the message
      # @return [void]
      def call_add_with_attributes_arg(logger, severity, message_or_progname_or_attributes, progname_or_attributes, &block)
        if logger.is_a?(Lumberjack::ContextLogger)
          logger.add(severity, message_or_progname_or_attributes, progname_or_attributes, &block)
        elsif block
          progname = message_or_progname_or_attributes unless progname_or_attributes.is_a?(Hash)
          logger.add(severity, progname, &block)
        else
          logger.add(severity, message_or_progname_or_attributes)
        end
      end

      # Guard against multiple loggers responding to the same method that takes
      # a block. In that case we don't want to call the block multiple times.
      # This does not include the logging methods like `info` but does include
      # methods like `tag` that are expected to be called with a block that
      # has business logic inside of it.
      #
      # @param name [Symbol] the method name to dispatch
      # @yield optional block to execute
      # @return [Object] the result of the method execution
      def dispatch_block_method(name, ...)
        loggers = broadcasts.select { |logger| logger.respond_to?(name) }

        if loggers.none?
          result = yield if block_given?
          return result
        end

        return loggers.first.send(name, ...) if loggers.one?

        message = "BroadcastLogger cannot call #{name} on multiple loggers with a block."
        loggers.first.warn("#{message} It was called on this logger.")
        loggers[1..].each { |logger| logger.warn("#{message} It was not called on this logger.") }
        loggers.first.send(name, ...)
      end
    end
  end
end
