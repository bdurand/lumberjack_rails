# frozen_string_literal: true

module Lumberjack
  module Rails
    # This Rack middleware provides a hook for adding attributes from the request
    # onto the Rails.logger context so that they will appear on all log entries
    # for the request.
    class RequestAttributesMiddleware
      # @param app [#call] The Rack application.
      # @param attributes_block [Proc] A block that takes the Rack request and returns
      #   a hash of attributes to add to the logger context for the request.
      #   The block will be called with an ActionDispatch::Request object.
      def initialize(app, attributes_block)
        unless attributes_block.respond_to?(:call)
          raise ArgumentError.new("attributes_block must be a Proc or callable object")
        end

        @app = app
        @attributes_block = attributes_block
      end

      # Process a request through the middleware stack with Lumberjack context.
      #
      # @param env [Hash] the Rack environment hash
      # @return [Array] the Rack response array
      def call(env)
        return @app.call(env) if ::Rails.logger.nil?

        Lumberjack::Rails.logger_context do
          attributes = @attributes_block.call(ActionDispatch::Request.new(env))
          if attributes.is_a?(Hash)
            ::Rails.logger.tag(attributes)
          elsif !attributes.nil?
            warn "RequestAttributesMiddleware attributes_block did not return a Hash, got #{attributes.class.name}"
          end

          @app.call(env)
        end
      end
    end
  end
end
