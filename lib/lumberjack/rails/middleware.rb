# frozen_string_literal: true

module Lumberjack
  module Rails
    # This Rack middleware provides a convenient way to set up logger attributes for each request.
    # The attributes are defined in a callable object that must return a hash. Attributes will be applied
    # to Rails.logger.
    class Middleware
      # @param app [#call] The Rack application.
      # @param attributes_block [Proc] A callable object that returns a hash of logger attributes.
      def initialize(app, attributes_block = nil)
        @app = app
        @attributes_block = attributes_block

        if @attributes_block && !@attributes_block.respond_to?(:call)
          raise ArgumentError.new("attributes_block must respond to call")
        end
      end

      # Process a request through the middleware stack with Lumberjack context.
      #
      # @param env [Hash] the Rack environment hash
      # @return [Array] the Rack response array
      def call(env)
        Lumberjack::Rails.logger_context do
          attributes = logger_attributes(env) if @attributes_block
          ::Rails.logger&.tag(attributes) if attributes.is_a?(Hash)
          @app.call(env)
        end
      end

      private

      # Extract logger attributes from the request environment.
      #
      # @param env [Hash] the Rack environment hash
      # @return [Hash, nil] the logger attributes or nil if none
      def logger_attributes(env)
        request = ActionDispatch::Request.new(env)
        @attributes_block&.call(request)
      end
    end
  end
end
