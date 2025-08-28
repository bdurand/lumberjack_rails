# frozen_string_literal: true

module Lumberjack::Rails
  # Extension for the Lumberjack::EntryFormatter that adds support for adding the array of
  # tags added by ActiveSupport::TaggedLogging.
  #
  # This module integrates ActiveSupport's tagged logging mechanism with Lumberjack's
  # entry formatting, ensuring that tags from Rails' tagged logging are properly
  # included in the formatted log output.
  module TaggedLoggingFormatter
    # Format a log message with support for ActiveSupport tagged logging.
    #
    # @param message [String] the log message to format
    # @param tags [Hash, nil] existing tags to include in the formatted output
    # @return [String] the formatted log message
    def format(message, tags)
      tagged_values = current_tags if respond_to?(:current_tags)
      if tagged_values && !tagged_values.empty?
        tagged = {"tags" => tagged_values}
        new_tags = tags.nil? ? tagged : tags.merge(tagged)
      else
        new_tags = tags
      end

      super(message, new_tags)
    end
  end
end
