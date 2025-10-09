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
#     The device to write logs to (file path, IO object, Lumberjack Device)
#
#   config.lumberjack.level (default: config.log_level)
#     The log level for the Lumberjack logger
#
#   config.lumberjack.attributes (default: nil)
#     Attributes to apply to log messages
#
#   config.lumberjack.shift_age (default: 0)
#     The age (in seconds) of log files before they are rotated or
#     a shift name (daily, weekly, monthly)
#
#   config.lumberjack.shift_size (default: 1048576)
#     The size (in bytes) of log files before they are rotated if shift_age
#     is set to 0.
#
#   config.lumberjack.log_rake_tasks (default: false)
#     Whether to redirect $stdout and $stderr to Rails.logger for rake tasks
#     that depend on the :environment task when using a Lumberjack::Logger
#
#   config.lumberjack.middleware (default: true)
#     Whether to install Rack middleware that adds a Lumberjack context to each request.
#
#   config.lumberjack.request_attributes (default: nil)
#     A proc or hash to add tags to log entries for each request. If a proc,
#     it will be called with the request object. If a hash, it will be used
#     as static tags for all requests.
#
#   config.lumberjack.silence_rack_request_started (default: false)
#     Whether to silence the "Started ..." log lines in Rack::Logger. You may want to silence
#     this entry if it is just creating noise in your production logs.
#
#   config.lumberjack.*
#     All other options are sent as options to the Lumberjack logger
#     constructor.
#
# Example usage in config/application.rb:
#   config.log_level = :info
#   config.lumberjack.attributes = {app: "my_app", host: Lumberjack::Utils.hostname}
#   config.lumberjack.device = STDOUT  # optional override
class Lumberjack::Rails::Railtie < ::Rails::Railtie
  class << self
    # Create a Lumberjack logger based on Rails configuration.
    #
    # @param config [Rails::Application::Configuration] the Rails application configuration
    # @param log_file_path [String, nil] optional path to the log file
    # @return [Lumberjack::Logger, nil] the configured logger or nil if not enabled
    def lumberjack_logger(config, log_file_path = nil)
      return nil if config.logger
      return nil if config.lumberjack.nil? || config.lumberjack == false
      return nil unless config.lumberjack.enabled

      # Determine the log device
      device = config.lumberjack.device
      if device.nil?
        if log_file_path
          FileUtils.mkdir_p(File.dirname(log_file_path)) unless File.exist?(File.dirname(log_file_path))
          device = log_file_path
        else
          device = $stdout
        end
      end

      # Determine the log level
      level = config.lumberjack.level || config.log_level || :debug

      # Get default attributes
      attributes = config.lumberjack.attributes
      if config.log_tags
        attributes ||= {}
        attributes["tags"] = config.log_tags
      end

      shift_age = config.lumberjack.shift_age || 0
      shift_size = config.lumberjack.shift_size || 1048576

      # Create logger options
      logger_options = config.lumberjack.to_h.except(
        :enabled,
        :raise_logger_errors,
        :device, :level,
        :progname,
        :attributes,
        :shift_age,
        :shift_size,
        :log_rake_tasks,
        :middleware,
        :request_attribute,
        :silence_rack_request_started
      )

      logger_options.merge!(
        level: level,
        formatter: config.lumberjack.formatter,
        progname: config.lumberjack.progname
      )

      # Create the Lumberjack logger
      logger = Lumberjack::Logger.new(device, shift_age, shift_size, **logger_options)
      logger.tag!(attributes) if attributes
      logger.formatter.prepend(active_record_entry_formatter)

      logger
    end

    # Build an entry formatter for ActiveRecord models to log them with their class and id
    # when logged as attributes.
    #
    # @return [Lumberjack::EntryFormatter] the entry formatter for ActiveRecord models
    def active_record_entry_formatter
      Lumberjack::EntryFormatter.build do |formatter|
        formatter.add_attribute_class("ActiveRecord::Base", :id)
      end
    end

    # Redirect standard streams ($stdout, $stderr) to logger instances.
    #
    # @param config [Rails::Application::Configuration] the Rails application configuration
    # @param logger [Lumberjack::Logger] the logger to redirect streams to
    # @return [void]
    def set_standard_streams_to_loggers!(config, logger)
      return unless config.lumberjack&.log_rake_tasks
      return unless logger.respond_to?(:fork) && logger.respond_to?(:puts)

      if !$stdout.tty? && !$stdout.is_a?(::Logger)
        stdout_logger = logger.fork
        stdout_logger.default_severity = :info
        $stdout = stdout_logger
      end

      if !$stderr.tty? && !$stderr.is_a?(::Logger)
        stderr_logger = logger.fork
        stderr_logger.default_severity = :warn
        $stderr = stderr_logger
      end
    end
  end

  config.lumberjack = ActiveSupport::OrderedOptions.new
  config.lumberjack.enabled = true
  config.lumberjack.middleware = true
  config.lumberjack.log_rake_tasks = false
  config.lumberjack.template = "[{{time}} {{severity(padded)}} {{progname}} ({{pid}})] {{tags}} {{message}} -- {{attributes}}"
  config.lumberjack.raise_logger_errors = !(Rails.env.development? || Rails.env.test?)

  initializer "lumberjack.configure_logger", before: :initialize_logger do |app|
    Lumberjack.raise_logger_errors = app.config.lumberjack.raise_logger_errors
    Lumberjack::Rails.silence_rack_request_started = app.config.lumberjack.silence_rack_request_started

    logger = Lumberjack::Rails::Railtie.lumberjack_logger(app.config, app.paths["log"]&.first)
    app.config.logger = logger if logger
  end

  initializer "lumberjack.insert_middleware" do |app|
    next unless app.config.lumberjack&.enabled && config.lumberjack.middleware

    app.middleware.unshift(Lumberjack::Rails::Middleware)
  end

  config.after_initialize do
    # Enhance the :environment task to set standard streams to loggers
    # This will apply to any rake task that depends on :environment
    if defined?(Rake::Task) && Rake::Task.task_defined?(:environment)
      Rake::Task[:environment].enhance do
        Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(::Rails.application.config, ::Rails.logger)
      end
    end
  end
end
