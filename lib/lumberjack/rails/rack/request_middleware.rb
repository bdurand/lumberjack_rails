# frozen_string_literal: true

module Lumberjack
  module Rails
    module Rack
      class RequestMiddleware
        def initialize(app, logger_handler = nil)
          @app = app
          @logger_handler = logger_handler

          if @logger_handler && !@logger_handler.respond_to?(:call)
            raise ArgumentError.new("logger_handler must respond to call")
          end
        end

        def call(env)
          # Wrap the request in a logger context for both Rails.logger and ActionController logger
          action_controller_logger = ActionController::Base.logger if defined?(ActionController::Base)

          Lumberjack::Rails.logger_context(action_controller_logger) do
            if @logger_handler
              # If a logger handler is provided, use it to set tags
              tags = @logger_handler.call(env)
              if tags.is_a?(Hash) && !tags.empty?
                Lumberjack.tag(tags) do
                  @app.call(env)
                end
              else
                @app.call(env)
              end
            else
              @app.call(env)
            end
          end
        end
      end

      # Alias for backward compatibility
      RequestTaggingMiddleware = RequestMiddleware
    end
  end
end
