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
#   config.lumberjack.global_attributes (default: nil)
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
#   config.lumberjack.tag_request_logs (default: nil)
#     A proc or hash to add tags to log entries for each request. If a proc,
#     it will be called with the request object. If a hash, it will be used
#     as static tags for all requests.
#
#   config.lumberjack.*
#     All other options are sent as options to the Lumberjack logger
#     constructor.
#
# Example usage in config/application.rb:
#   config.log_level = :info
#   config.attributes = {app: "my_app", host: Lumberjack::Utils.hostname}
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
        log_file_path = app_paths["log"]&.first
        if log_file_path
          FileUtils.mkdir_p(File.dirname(log_file_path)) unless File.exist?(File.dirname(log_file_path))
          device = log_file_path
        end
      end

      # Determine the log level
      level = config.lumberjack.level || config.log_level || :debug

      # Get default attributes
      attributes = config.lumberjack.global_attributes
      if config.log_tags
        attributes ||= {}
        attributes["tags"] = config.log_tags
      end

      shift_age = config.lumberjack.shift_age || 0
      shift_size = config.lumberjack.shift_size || 1048576

      # Create logger options
      logger_options = config.lumberjack.to_h.except(
        :enabled, :device, :level, :progname, :global_attributes, :shift_age, :shift_size, :log_rake_tasks, :tag_request_logs
      )
      logger_options.merge!(
        level: level,
        formatter: config.lumberjack.formatter,
        progname: config.lumberjack.progname
      )

      # Create the Lumberjack logger
      logger = Lumberjack::Logger.new(device, shift_age, shift_size, **logger_options)
      logger.tag!(attributes) if attributes

      logger
    end

    def set_standard_streams_to_loggers!(config, logger)
      return unless config.lumberjack&.log_rake_tasks
      return unless logger.respond_to?(:local_logger) && logger.respond_to?(:puts)

      if !$stdout.tty? && !$stdout.is_a?(::Logger)
        stdout_logger = logger.local_logger
        stdout_logger.default_severity = :info
        $stdout = stdout_logger
      end

      if !$stderr.tty? && !$stderr.is_a?(::Logger)
        stderr_logger = logger.local_logger
        stderr_logger.default_severity = :warn
        $stderr = stderr_logger
      end
    end
  end

  config.lumberjack = ActiveSupport::OrderedOptions.new

  initializer "lumberjack.configure_logger", before: :initialize_logger do |app|
    logger = Lumberjack::Rails::Railtie.lumberjack_logger(app.config, app.paths)
    app.config.logger = logger if logger
  end

  initializer "lumberjack.insert_context_middleware", before: :build_middleware_stack do |app|
    # Add the ContextMiddleware to the very start of the middleware chain
    # This ensures that all subsequent middleware and the application itself
    # run within the Lumberjack logger context
    if app.config.lumberjack&.enabled != false
      app.middleware.insert_before 0, Lumberjack::Rails::Rack::ContextMiddleware
    end
  end

  initializer "lumberjack.insert_tag_logs_middleware", after: :build_middleware_stack do |app|
    next if app.config.lumberjack&.enabled != false

    attributes_block = app.config.lumberjack.tag_request_logs
    if attributes_block.is_a?(Hash)
      attributes_hash = attributes_block
      attributes_block = lambda { |request| attributes_hash }
    end
    next unless attributes_block.respond_to?(:call)

    # Insert after ActionDispatch::RequestId or fallback to after ContextMiddleware
    request_id_middleware = app.middleware.detect { |middleware| middleware.klass == ActionDispatch::RequestId }
    if request_id_middleware
      app.middleware.insert_after ActionDispatch::RequestId, Lumberjack::Rails::Rack::TagLogsMiddleware, attributes_block
    else
      app.middleware.insert_after Lumberjack::Rails::Rack::ContextMiddleware, Lumberjack::Rails::Rack::TagLogsMiddleware, attributes_block
    end
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
