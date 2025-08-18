# frozen_string_literal: true

module Lumberjack
  module Rails
    module TaggedLogger
      class << self
        # Template for a Lumberjack Writer device that prepends tags to the start of the message
        # like ActiveSupport::TaggedLogging does.
        #
        # @return [String]
        def template
          "[:time :severity :progname(:pid)] :tags :message :attributes"
        end

        # Formatter designed for the "tags" attribute to format it as like ActiveSupport::TaggedLogging
        # does. Each tag is enclosed in "[]" and separated by spaces.
        #
        # @return [Proc]
        def tags_format
          lambda do |tags|
            tags = Array(tags)
            return nil if tags.empty?

            "[#{tags.join("] [")}]"
          end
        end

        # Entry formatter for log messages to include the "tags" attribute that includes the
        # formatter on the "tags" attribute.
        #
        # @return [Lumberjack::EntryFormatter]
        def entry_formatter
          tags_attribute = tags_format
          Lumberjack::EntryFormatter.build do
            attributes do
              add_attribute("tags", tags_attribute)
            end
          end
        end
      end

      def formatter=(value)
        # ActiveSupport::TaggedLogging will cause ActiveSupport::BroadcastLogger to try
        # and set the
        return if value.is_a?(ActiveSupport::Logger::SimpleFormatter)

        super
      end
    end
  end
end
