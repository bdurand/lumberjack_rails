# frozen_string_literal: true

module Lumberjack
  module Rails
    module ActionMailboxExtension
      def perform_processing(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
