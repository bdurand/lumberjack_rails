# frozen_string_literal: true

module Lumberjack
  module Rails
    # This Rack middleware provides a Lumberjack context for each request.
    class Middleware
      # @param app [#call] The Rack application.
      def initialize(app)
        @app = app
      end

      # Process a request through the middleware stack with Lumberjack context.
      #
      # @param env [Hash] the Rack environment hash
      # @return [Array] the Rack response array
      def call(env)
        Lumberjack::Rails.logger_context do
          @app.call(env)
        end
      end
    end
  end
end
