# frozen_string_literal: true

module Lumberjack
  module Rails
    module Rack
      class RequestMiddleware
        def initialize(app)
          @app = app
        end

        def call(env)
          Lumberjack::Rails.logger.context do
            add_request_tags(ActionDispatch::Request.new(env))
            @app.call(env)
          end
        end
      end
    end
  end
end
