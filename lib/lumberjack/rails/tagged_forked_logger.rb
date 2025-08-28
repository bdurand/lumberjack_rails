# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for Lumberjack::ForkedLogger to support ActiveSupport tagged logging.
    #
    # This module adds tagged logging capabilities to forked loggers by
    # delegating tagged calls to the parent logger when available.
    module TaggedForkedLogger
      # Execute a block with the specified tags if the parent logger supports tagging.
      #
      # @param tags [Array] the tags to apply during block execution
      # @yield the block to execute with the specified tags
      # @return [Object] the result of the block execution, or nil if parent doesn't support tagging
      def tagged(*tags, &block)
        if parent_logger.respond_to?(:tagged)
          parent_logger.tagged(*tags, &block)
        end
      end
    end
  end
end
