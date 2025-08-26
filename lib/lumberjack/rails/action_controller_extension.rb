# frozen_string_literal: true

module Lumberjack
  module Rails
    module ActionControllerExtension
      def process(...)
        Lumberjack::Rails.logger_context(logger) { super }
      end
    end
  end
end
