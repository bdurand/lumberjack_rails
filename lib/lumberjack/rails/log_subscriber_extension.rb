# frozen_string_literal: true

module Lumberjack::Rails
  module LogSubscriberExtension
    extend ActiveSupport::Concern

    class_methods do
      def logger
        class_logger = super
        class_logger = class_logger.call if class_logger.is_a?(Proc)

        @__logger ||= nil

        if class_logger.respond_to?(:fork)
          if !@__logger.is_a?(Lumberjack::ForkedLogger) || @__logger&.parent_logger != class_logger
            @__logger = class_logger.fork
          end
        else
          @__logger = class_logger
        end

        @__logger
      end
    end

    def logger
      self.class.logger
    end
  end
end
