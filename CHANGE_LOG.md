# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.2

### Fixed

- Fixed local log levels set with `silence` and `log_at` bleeding between unrelated loggers. ActiveSupport 8.1 sets the key used to store the local log level in the logger constructor, which Lumberjack loggers do not call, so all loggers were sharing a single local level per thread.
- Forked loggers now share the ActiveSupport local log level with their parent logger so that calling `silence` or `log_at` on the main logger applies to log subscriber loggers forked from it.
- `ActiveSupport::BroadcastLogger#local_level` now reads from the broadcasted loggers on ActiveSupport versions prior to 8.1 so that `silence` and `log_at` behave consistently across versions.
- `ActiveSupport::BroadcastLogger#add` now coerces the severity with `Lumberjack::Severity` so that Lumberjack-specific severities like `:trace` work and so that it does not depend on `Logger::Severity.coerce`, which only exists in logger gem 1.6 and later.
- `tagged` on a forked logger now executes the block even when the parent logger does not support tagged logging. Previously the block was silently skipped.
- Fixed typo in the Railtie that failed to exclude `config.lumberjack.request_attributes_proc` from the options passed to the logger constructor.
- The Railtie no longer mutates the `config.lumberjack.attributes` hash and no longer copies dynamic `config.log_tags` values (Symbols and Procs) as static logger attributes. Dynamic tags are evaluated per request by `Rails::Rack::Logger` and were being logged as literal values on entries outside of requests.
- `ActionController::LogSubscriber.add_process_log_attribute` now handles a static value of `false` correctly instead of storing `nil`.

## 1.0.1

### Changed

- Bumped minimu lumberjack version dependency to 2.0.3.
- Set logger context isolation level to `:thread` to match the default isolation level in ActiveSupport loggers.

## 1.0.0

### Added

- Initial release
