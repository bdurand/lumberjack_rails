# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for ActionCable::Connection::Base to wrap command processing with Lumberjack context.
    #
    # This module ensures that all logging within ActionCable command processing is wrapped
    # with the appropriate Lumberjack logger context, maintaining log consistency
    # and enabling tagged logging features.
    module ActionCableExtension
      # Override the command method to wrap it with Lumberjack logger context.
      #
      # @return [Object] the result of the original command method
      def command(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
