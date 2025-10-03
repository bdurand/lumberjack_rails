# Lumberjack Rails

[![Continuous Integration](https://github.com/bdurand/lumberjack_rails/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/lumberjack_rails/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/lumberjack_rails.svg)](https://badge.fury.io/rb/lumberjack_rails)

The `lumberjack_rails` gem provides support for using the [lumberjack](https://github.com/bdurand/lumberjack) logging library in Rails applications.

Rails has some of its own extensions to the Ruby standard library logger, and this gem bridges the gap between the two logging systems to add Lumberjack features to the `Rails.logger` and Rails features to Lumberjack loggers.

## Usage

With this gem installed, your main application logger will be a Lumberjack logger. The logger that gets initialized is defined by your application's configuration.

### Configuration Options

#### `config.lumberjack.enabled`

Enables or disables the Lumberjack logger. If this is set to `false`, then Lumberjack will not be used.

#### `config.lumberjack.level`

Sets the log level for the Lumberjack logger. This can be set to any valid log level supported by Lumberjack. This will defer to the standard Rails `config.log_level` setting or default to `:debug` if neither is set.

#### `config.lumberjack.device`

The device to write logs to (file path, IO object, etc.). Defaults to the Rails log file.

#### `config.lumberjack.attributes`

Hash of attributes to apply to all log messages. These attributes will be included in every log entry.

#### `config.lumberjack.shift_age`

The age (in seconds) of log files before they are rotated, or a shift name (`daily`, `weekly`, `monthly`). The default is no log rotation. See the [logger](https://github.com/ruby/logger) gem documentation for details.

#### `config.lumberjack.shift_size`

The size (in bytes) of log files before they are rotated if `shift_age` is set to an integer. Defaults to `1048576` (1MB). See the [logger](https://github.com/ruby/logger) gem documentation for details.

#### `config.lumberjack.log_rake_tasks`

Whether to redirect `$stdout` and `$stderr` to `Rails.logger` for rake tasks that depend on the `:environment` task when using a Lumberjack::Logger. Defaults to `false`.

> [!TIP]
> This is useful for getting output from `db:migrate` and other rake tasks run in production into your logs. It can often be difficult to track down issues in these tasks without proper logging.

> [!NOTE]
> This setting is ignored when running in an interactive terminal session.

#### `config.lumberjack.middleware`

Whether to install Rack middleware that adds a Lumberjack context to each request. Defaults to `true`.

#### `config.lumberjack.request_attributes`

A proc or hash to add tags to log entries for each Rack request. If this is a proc, it will be called with the request object. If this is a hash, it will be used as static tags for all requests.

> [!TIP]
> You can use this feature to add both static attributes (using a hash) and dynamic attributes (using a proc) to all log entries within a request context.

#### Additional Options

All other options in the `config.lumberjack` namespace are passed as options to the Lumberjack logger constructor, allowing you to configure any other Lumberjack-specific settings.

So, if you want to set a specific log format, you could set `config.lumberjack.template` to a [custom template](https://github.com/bdurand/lumberjack/blob/main/lib/lumberjack/template.rb) string. You can build your logger formatter with `config.lumberjack.formatter`.

#### Example Configuration

Here's an example of how you might configure Lumberjack in your `config/application.rb`:

```ruby
config.log_level = :info

# Set the program name on the logger
config.lumberjack.progname = Rails.application.railtie_name

# Add values we want on all log entries
config.lumberjack.attributes = {
  host: Lumberjack::Utils.hostname, # Ensures hostname is UTF-8 encoded
  pid: Lumberjack::Utils.global_pid # Returns a global PID value across all hosts
}

config.lumberjack.device = STDOUT

# Build the log entry formatter
config.lumberjack.formatter = Lumberjack.build_formatter do |formatter|
  formatter.add(ActiveRecord::Base, :id)

  # Format the :tags attribute as tags (e.g. [tag1] [tag2])
  formatter.add_attribute("tags", :tags)

  formatter.add_attribute("cost", :round, 2)
  formatter.add_attribute_class("User") { |user| {id: user.id, username: user.username} }
end

# Use a custom template that adds the request id on all log entry lines.
config.lumberjack.template = "{{time}} {{severity}} {{progname}} {{request_id}}] {{tags}} {{message}} -- {{attributes}}"
config.lumberjack.additional_lines = "> :request_id :message"

# Format log attributes as "[name=value]" (default is [name:value])
config.lumberjack.attribute_format = "[name=value]"

# Add the request id to all web requests
config.lumberjack.request_attributes = { request_id: -> (request) { request.request_id } }

# Convert db:migrate and other rails task output to log entries
config.lumberjack.log_rake_tasks = true
```

> [!TIP]
> If you are using a logging pipeline in production that supports [JSONL](https://jsonlines.org/) logs, then check out the [lumberjack_json_device](https://github.com/bdurand/lumberjack_json_device). The gem provides a mechanism for defining the JSON schema for your logs and outputting them to JSONL.

> [!TIP]
> If you want more easily readable log output in development or test environments, you can set the `config.lumberjack.template` to `:test`. If you have attributes that are logged on every entry but don't want them cluttering up your development logs, you can set `config.lumberjack.exclude_attributes` to the attribute names to exclude.

```ruby
config.lumberjack.template = :test
config.lumberjack.exclude_progname = true
config.lumberjack.exclude_attributes = [:host, :request_id]
```

### TaggedLogger

Rails has its own solution for logging metadata in the `tagged` method added to logger which can add an array of tags to log entries.

Lumberjack supports the `tagged` method and will put the tags into the `tags` attribute. You can format these similar to how Rails formats them in the logger template with the `:tags` formatter.

```ruby
# The :tags placeholder will be replaced with the tags attribute. This is the default template.
config.lumberjack.template = "[:time :severity :progname (:pid)] :tags :message -- :attributes"

# Add the :tags formatter. If you don't do this, then the tags will be formatted as an inspected array.
config.lumberjack.formatter = Lumberjack.build_formatter do |formatter|
  formatter.add_attribute(:tags, :tags)
end
```

### Broadcast Logger

Rails provides a built-in mechanism for broadcasting log messages to multiple destinations. `Rails.logger` is actually an `ActiveSupport::BroadcastLogger` object wrapping one or more underlying loggers. When you call a method on `Rails.logger`, it will call that method on all underlying loggers. This can create some problems for methods that take a block since that block could get called once for each logger being broadcast to. Only one Lumberjack logger should be added `Rails.logger`. If more than one is added, method like `tag` or `context` that take a block will only be called on one of the loggers.

If you want to send your logs to multiple devices with Lumberjack, you can use the Multi device instead.

The one place that Rails uses multiple loggers out of the box is in development mode where logs are also sent to the console in addition to the log file. This functionality is supported.

### Lumberjack Contexts

Contexts are used in Lumberjack to provide isolation for changes to your logger. Within a context block, you can change the log level, progname, or attributes and they will only apply within that block execution.

Contexts will be added via `around` callbacks to the following frameworks if they are installed:

- ActionController
- ActiveJob
- ActionCable
- ActionMailer
- ActionMailbox

In addition, a Rack middleware will be added to ensure a context is set on Rails.logger for each request.

This allows you to change the log level or tag attributes on `Rails.logger` within your application code in these frameworks without affecting the global logger or the settings in any concurrent requests.

### Log Subscribers

Rails comes with several built-in log subscribers that are extended with Lumberjack. These include:

- `ActiveRecord::LogSubscriber`
- `ActionController::LogSubscriber`
- `ActionDispatch::LogSubscriber`
- `ActionView::LogSubscriber`
- `ActiveJob::LogSubscriber`
- `ActionMailer::LogSubscriber`
- `ActiveStorage::LogSubscriber`

These log subscribers will all use fork loggers. This these forked loggers are isolated from the main logger allowing you to change the log level and add attributes that is isolated to that log subscriber.

```ruby
# Set up log subscriber in an initializer
ActiveSupport.on_load(:action_controller) do
  ActionController::LogSubscriber.logger.level = :info # Override the log level
  ActionController::LogSubscriber.logger.tag!(user_id: Current.user_id) # Tag all log entries with the user ID
end
```

### Log Formatter

ActiveRecord models logged in attributes will automatically be logged with a formatter that will only log the class name and id for the model. You can add additional formatters for `ApplicationRecord` or for your models to override this behavior.

### Testing

Lumberjack comes with built-in support for testing that critical log messages are generated. See the [lumberjack documentation](https://github.com/bdurand/lumberjack#testing-utilities) for more information.

If you are using RSpec, then you can use the [lumberjack_rails_rspec](https://github.com/bdurand/lumberjack_rails_rspec) gem for to add RSpec matchers for testing log messages to your test suite.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lumberjack_rails'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install lumberjack_rails
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
