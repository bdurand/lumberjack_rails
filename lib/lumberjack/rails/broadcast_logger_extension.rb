# frozen_string_literal: true

module Lumberjack
  module Rails
    module BroadcastLoggerExtension
      def local_logger(level: nil, progname: nil, tags: nil)
        logger = Lumberjack::LocalLogger.new(self)
        logger.level = level if level
        logger.progname = progname if progname
        logger.tag!(tags) if tags && !tags.empty?
        logger
      end
    end
  end
end
