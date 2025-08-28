# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for ActionController::Base to wrap request processing with Lumberjack context.
    #
    # This module ensures that all logging within a controller action is wrapped
    # with the appropriate Lumberjack logger context, maintaining log consistency
    # and enabling tagged logging features.
    module ActionControllerExtension
      # Override the process method to wrap it with Lumberjack logger context.
      #
      # @return [Object] the result of the original process method
      def process(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
