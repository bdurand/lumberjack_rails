# frozen_string_literal: true

module Lumberjack
  module Rails
    module Rack
      class ContextMiddleware
        def initialize(app)
          @app = app
        end

        def call(env)
          action_controller_logger = ActionController::Base.logger if defined?(ActionController::Base)
          Lumberjack::Rails.logger_context(action_controller_logger) do
            @app.call(env)
          end
        end
      end
    end
  end
end
