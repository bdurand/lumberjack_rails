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
    end
  end
end
