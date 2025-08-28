# frozen_string_literal: true

module Lumberjack
  module Rails
    # Extension for ActionMailbox::Base to wrap mailbox processing with Lumberjack context.
    #
    # This module ensures that all logging within mailbox processing is wrapped
    # with the appropriate Lumberjack logger context, maintaining log consistency
    # and enabling tagged logging features.
    module ActionMailboxExtension
      # Override the perform_processing method to wrap it with Lumberjack logger context.
      #
      # @return [Object] the result of the original perform_processing method
      def perform_processing(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
