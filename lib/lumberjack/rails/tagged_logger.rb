# frozen_string_literal: true

module Lumberjack
  module Rails
    module TaggedLogger
      def formatter=(value)
        # ActiveSupport::TaggedLogging will cause ActiveSupport::BroadcastLogger to try
        # and set the
        return if value.is_a?(ActiveSupport::Logger::SimpleFormatter)

        super
      end
    end
  end
end
