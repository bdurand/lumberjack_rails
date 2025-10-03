# frozen_string_literal: true

module Lumberjack::Rails
  module RackLoggerExtension
    private

    def started_request_message(request)
      return if Lumberjack::Rails.silence_rack_request_started

      super
    end
  end
end
