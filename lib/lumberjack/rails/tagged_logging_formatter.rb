# frozen_string_literal: true

module Lumberjack::Rails
  # Extension for the Lumberjack::EntryFormatter that adds support for adding the array of
  # tags added by ActiveSupport::TaggedLogging.
  module TaggedLoggingFormatter
    def format(message, tags)
      tagged_values = current_tags if respond_to?(:current_tags)
      if tagged_values && !tagged_values.empty?
        tagged = {"tagged" => tagged_values}
        new_tags = tags.nil? ? tagged : tags.merge(tagged)
      else
        new_tags = tags
      end

      super(message, new_tags)
    end
  end
end
