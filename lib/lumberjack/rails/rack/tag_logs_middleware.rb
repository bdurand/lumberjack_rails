# frozen_string_literal: true

module Lumberjack
  module Rails
    module Rack
      # This Rack middleware provides a convenient way to set up logger attributes for each request.
      # The attributes are defined in a callable object that must return a hash. Attributes will be applied
      # to all Lumberjack loggers.
      class TagLogsMiddleware
        # @param app [#call] The Rack application.
        # @param attributes_block [Proc] A callable object that returns a hash of logger attributes.
        def initialize(app, attributes_block = nil)
          @app = app
          @attributes_block = attributes_block

          if @attributes_block && !@attributes_block.respond_to?(:call)
            raise ArgumentError.new("attributes_block must respond to call")
          end
        end

        def call(env)
          request = ActionDispatch::Request.new(env)
          logger_attributes = @attributes_block&.call(request)
          if logger_attributes.is_a?(Hash)
            Lumberjack.tag(logger_attributes) do
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
