# frozen_string_literal: true

module Lumberjack::Rails
  # This extension to the ActionController::LogSubscriber class allows specifying log attributes that
  # will only be applied on the process_action event. This log entry already serves as the canonical
  # log entry for requests and includes metadata such as duration, allocations, etc. With this extension
  # you can add whatever additonal attributes you want to summarize what happened during the request
  # as log attributes. This gives you more flexibility to add context to your request logs.
  #
  # You can add dynamically evaluated attributes by providing a block that takes the event as an argument.
  #
  # @example
  #   ActionController::LogSubscriber.add_process_log_attribute(:ip_address) do |event|
  #     event.payload.request.remote_ip
  #   end
  #
  #   ActionController::LogSubscriber.add_process_log_attribute(:duration) do |event|
  #     event.duration
  #   end
  module ActionControllerLogSubscriberExtension
    extend ActiveSupport::Concern

    prepended do
      @lumberjack_process_log_attributes = {}
      @lumberjack_process_log_blocks = []
    end

    class_methods do
      # Add a log attribute to be included in the process_action log entry. You must provide
      # either a static value or a block that takes the event as an argument to dynamically
      # evaluate the value at log time.
      #
      # @param name [String, Symbol] the name of the log attribute
      # @param value [Object] the static value of the log attribute (optional if block is provided)
      # @yield [event] a block that takes the event as an argument to dynamically evaluate the value (optional if value is provided)
      # @raise [ArgumentError] if neither a value nor a block is provided, or if both are provided
      # @return [void]
      def add_process_log_attribute(name, value = nil, &block)
        raise ArgumentError.new("Must provide a value or a block") if value.nil? && block.nil?
        raise ArgumentError.new("Cannot provide both a value and a block") if value && block

        @lumberjack_process_log_attributes[name.to_s] = value || block
      end

      # Add log attributes to be included in the process_action log entry. The block must
      # take an ActiveSupport::Notifications::Event as an argument and return a hash.
      #
      # @yieldparam event [ActiveSupport::Notifications::Event] the event being processed
      # @yieldreturn [Hash] a hash of log attributes to be merged into the log entry attributes.
      # @return [void]
      def process_log_attributes(&block)
        @lumberjack_process_log_blocks << block
      end

      # Get the log attributes to be included in the process_action log entry.
      #
      # @param event [ActiveSupport::Notifications::Event] the event being processed
      # @return [Hash{String => Object}] a hash of log attributes
      # @api private
      def eval_process_log_attributes(event)
        attributes = @lumberjack_process_log_attributes.each_with_object({}) do |(name, value_or_block), attrs|
          attrs[name] = if value_or_block.respond_to?(:call)
            value_or_block.call(event)
          else
            value_or_block
          end
        end

        @lumberjack_process_log_blocks.each do |block|
          attrs = block.call(event)
          attributes.merge!(Lumberjack::Utils.flatten_attributes(attrs)) if attrs.is_a?(Hash)
        end

        attributes
      end

      private

      # Used for testing.
      def clear_process_log_attributes
        @lumberjack_process_log_attributes = {}
        @lumberjack_process_log_blocks = []
      end
    end

    def process_action(event) # :nodoc:
      with_process_logger_attributes(event) do
        super
      end
    end

    private

    def with_process_logger_attributes(event, &block)
      attributes = self.class.eval_process_log_attributes(event) if logger
      if attributes && !attributes.empty?
        logger.tag(attributes, &block)
      else
        block.call
      end
    end
  end
end
