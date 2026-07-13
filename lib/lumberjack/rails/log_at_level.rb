# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension that provides log level override functionality.
    #
    # This module allows temporary overriding of the logger's level using
    # Rails' local_level mechanism while maintaining compatibility with
    # the underlying Lumberjack logger.
    module LogAtLevel
      # Get the effective log level, checking for local level override first.
      #
      # @return [Integer] the effective log level
      def level
        local_level || super
      end

      private

      # ActiveSupport::LoggerThreadSafeLevel#initialize sets this key, but Lumberjack
      # loggers never call super in their constructors, so without this override every
      # logger would share the nil key and local levels would bleed between loggers.
      def local_level_key
        @local_level_key ||= :"logger_thread_safe_level_#{object_id}"
      end
    end
  end
end
