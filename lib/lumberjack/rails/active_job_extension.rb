# frozen_string_literal: true

module Lumberjack
  module Rails
    module ActiveJobExtension
      def perform_now(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
