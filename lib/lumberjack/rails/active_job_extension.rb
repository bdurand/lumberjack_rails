# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for ActiveJob::Base to wrap job execution with Lumberjack context.
    #
    # This module ensures that all logging within job execution is wrapped
    # with the appropriate Lumberjack logger context, maintaining log consistency
    # and enabling tagged logging features.
    module ActiveJobExtension
      # Override the perform_now method to wrap it with Lumberjack logger context.
      #
      # @return [Object] the result of the original perform_now method
      def perform_now(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
