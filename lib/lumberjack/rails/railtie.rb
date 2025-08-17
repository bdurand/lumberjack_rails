# frozen_string_literal: true

# Railtie for integrating Lumberjack::Logger with Rails applications.
#
# This railtie replaces the standard Rails logger with a Lumberjack::Logger while
# maintaining compatibility with Rails' logging configuration options.
#
# Configuration options:
#   config.lumberjack.enabled (default: true)
#     Whether to replace Rails.logger with Lumberjack::Logger
#
#   config.lumberjack.device (default: Rails log file)
#     The device to write logs to (file path, IO object, etc.)
#
#   config.lumberjack.level (default: config.log_level)
#     The log level for the Lumberjack logger
#
#   config.lumberjack.tags (default: nil)
#     Tags to apply to log messages
#
#   config.lumberjack.shift_age (default: 0)
#     The age (in seconds) of log files before they are rotated or
#     a shift name (daily, weekly, monthly)
#
#   config.lumberjack.shift_size (default: 1048576)
#     The size (in bytes) of log files before they are rotated if shift_age
#     is set to 0.
#
#   config.lumberjack.*
#     All other options are sent as options to the Lumberjack logger
#     constructor.
#
# Example usage in config/application.rb:
#   config.log_level = :info
#   config.tags = {app: "my_app", host: Lumberjack::Utils.hostname}
#   config.lumberjack.device = STDOUT  # optional override
class Lumberjack::Rails::Railtie < ::Rails::Railtie
  class << self
    def lumberjack_logger(config, app_paths)
      return nil if config.logger
      return nil if config.lumberjack.nil? || config.lumberjack == false
      return nil if config.lumberjack.empty? || config.lumberjack.enabled == false

      # Determine the log device
      device = config.lumberjack.device
      if device.nil?
        # Use the same logic Rails uses to determine the log file
        log_file = app_paths["log"].first
        device = File.join(log_file, "#{Rails.env}.log")
      end

      # Determine the log level
      level = config.lumberjack.level || config.log_level || :debug

      # Get default tags
      tags = config.lumberjack.tags
      if config.log_tags
        tags ||= {}
        tags["tagged"] = config.log_tags
      end

      shift_age = config.lumberjack.shift_age || 0
      shift_size = config.lumberjack.shift_size || 1048576

      # Create logger options
      logger_options = config.lumberjack.to_h.except(:enabled, :device, :level, :progname, :tags, :shift_age, :shift_size)
      logger_options.merge!(
        level: level,
        formatter: config.lumberjack.formatter,
        progname: config.lumberjack.progname
      )

      # Create the Lumberjack logger
      logger = Lumberjack::Logger.new(device, shift_age, shift_size, **logger_options)
      logger.tag!(tags) if tags

      logger
    end
  end

  config.lumberjack = ActiveSupport::OrderedOptions.new

  initializer "lumberjack.configure_logger", before: "initialize_logger" do |app|
    logger = lumberjack_logger(app.config, app.paths)
    app.config.logger = logger if logger
  end

  # TODO: hook set stdout and stderr to Lumberjack logger with config option on rake tasks

  # TODO: Add logger context rack middleware with config
end
