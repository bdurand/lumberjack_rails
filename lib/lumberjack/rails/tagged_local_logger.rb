# frozen_string_literal: true

module Lumberjack
  module Rails
    module TaggedLocalLogger
      def tagged(*tags, &block)
        if parent_logger.respond_to?(:tagged)
          parent_logger.tagged(*tags, &block)
        end
      end
    end
  end
end
