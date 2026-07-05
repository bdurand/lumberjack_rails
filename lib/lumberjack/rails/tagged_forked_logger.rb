# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for Lumberjack::ForkedLogger to support ActiveSupport tagged logging.
    #
    # This module adds tagged logging capabilities to forked loggers by
    # delegating tagged calls to the parent logger when available. It also
    # shares the ActiveSupport local log level (used by silence and log_at)
    # with the parent logger so that silencing the parent silences the fork.
    module TaggedForkedLogger
      # Execute a block with the specified tags if the parent logger supports tagging.
      # If the parent logger does not support tagging, the block is still executed
      # without any tags applied.
      #
      # @param tags [Array] the tags to apply during block execution
      # @yield the block to execute with the specified tags
      # @return [Object] the result of the block execution
      def tagged(*tags, &block)
        if parent_logger.respond_to?(:tagged)
          parent_logger.tagged(*tags, &block)
        elsif block
          block.call
        else
          self
        end
      end

      # Get the local log level from the parent logger so that silence and log_at
      # on the parent apply to log entries written through the forked logger.
      #
      # @return [Integer, nil] the local log level
      def local_level
        parent_logger.respond_to?(:local_level) ? parent_logger.local_level : super
      end

      # Set the local log level on the parent logger.
      #
      # @param value [Integer, Symbol, nil] the local log level
      # @return [void]
      def local_level=(value)
        if parent_logger.respond_to?(:local_level=)
          parent_logger.local_level = value
        else
          super
        end
      end
    end
  end
end
