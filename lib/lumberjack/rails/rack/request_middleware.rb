# frozen_string_literal: true

module Lumberjack
  module Rails
    module Rack
      # This Rack middleware provides a convenient way to set up logger tags for each request.
      # The tags are defined in a callable object that must return a hash. Tags will be applied
      # to all Lumberjack loggers.
      class RequestMiddleware
        # @param app [#call] The Rack application.
        # @param logger_context_block [Proc] A callable object that returns a hash of logger tags.
        def initialize(app, logger_context_block = nil)
          @app = app
          @logger_context_block = logger_context_block

          unless @logger_context_block.respond_to?(:call)
            raise ArgumentError.new("logger_context_block must respond to call")
          end
        end

        def call(env)
          request = ActionDispatch::Request.new(env)
          logger_tags = @logger_context_block.call(request)
          if logger_tags.is_a?(Hash)
            Lumberjack.tag(logger_tags) do
              @app.call(env)
            end
          else
            @app.call(env)
          end
        end
      end
    end
  end
end
