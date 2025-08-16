# frozen_string_literal: true

module Lumberjack
  module Rails
    module BroadcastLoggerExtension
      extend ActiveSupport::Concern

      def tag(tags)
        if block_given?
          super
        else
          local_logger = Lumberjack::LocalLogger.new(self)
          local_logger.tag!(tags)
          local_logger
        end
      end
    end
  end
end
