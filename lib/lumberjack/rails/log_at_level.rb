# frozen_string_literal: true

module Lumberjack
  module Rails
    module LogAtLevel
      def level
        local_level || super
      end
    end
  end
end
