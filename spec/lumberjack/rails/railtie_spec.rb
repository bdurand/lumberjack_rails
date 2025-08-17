# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "Railtie" do
  require "rails"
  require_relative "../../../lib/lumberjack/rails/railtie"

  let(:config) do
    ActiveSupport::OrderedOptions.new.tap do |cfg|
      cfg.lumberjack = ActiveSupport::OrderedOptions.new
    end
  end

  let(:paths) do
    Rails::Paths::Root.new(Pathname.new(".")).tap do |p|
      p.add "log", to: "log"
    end
  end

  describe ".lumberjack_logger" do
    let(:logger) { Lumberjack::Rails::Railtie.lumberjack_logger(config, paths) }

    context "when lumberjack is not configured" do
      it "returns nil if config.lumbrjack is not defined" do
        config.delete(:lumberjack)
        expect(logger).to be_nil
      end

      it "returns nil if config.lumberjack is empty" do
        config.lumberjack = ActiveSupport::OrderedOptions.new
        expect(logger).to be_nil
      end

      it "returns nil if config.lumberjack.enabled is false" do
        config.lumberjack.enabled = false
        expect(logger).to be_nil
      end

      it "returns nil if config.logger is already set" do
        config.lumberjack.device = :test
        config.logger = Logger.new(File::NULL)
        expect(logger).to be_nil
      end
    end

    context "when lumberjack is configured" do
      before { config.lumberjack.device = :test }

      it "returns a lumberjack logger if config.lumberjack contains any values" do
        expect(logger).to be_a(Lumberjack::Logger)
      end

      it "sets the device from config.lumberjack.device" do
        device = Lumberjack::Device::Test.new
        config.lumberjack.device = device
        expect(logger.device).to equal(device)
      end

      it "uses the default log file if config.lumberjack.device is not set" do
        log_file_path = File.join(paths["log"].first, "#{Rails.env}.log")
        begin
          FileUtils.mkdir_p(paths["log"].first)
          config.lumberjack.device = nil
          expect(logger.device).to be_a(Lumberjack::Device::Writer)
          expect(logger.device.path).to eq(log_file_path)
        ensure
          FileUtils.rm_f(log_file_path)
          FileUtils.rmdir(paths["log"].first)
        end
      end

      it "sets the logger level with config.log_level" do
        config.log_level = :info
        expect(logger.level).to eq(Logger::INFO)
      end

      it "overrides config.log_level with config.lumberjack.level" do
        config.log_level = :info
        config.lumberjack.level = :warn
        expect(logger.level).to eq(Logger::WARN)
      end

      it "adds config.lumberjack.tags to the logger" do
        config.lumberjack.tags = {foo: "bar"}
        expect(logger.tags).to eq("foo" => "bar")
      end

      it "adds tagged logger tags from config.log_tags" do
        config.log_tags = ["foo", "bar"]
        expect(logger.tags).to eq("tagged" => ["foo", "bar"])
      end

      it "merges config.lumberjack.tags and config.log_tags" do
        config.lumberjack.tags = {baz: "qux"}
        config.log_tags = ["foo", "bar"]
        expect(logger.tags).to eq("baz" => "qux", "tagged" => ["foo", "bar"])
      end

      it "passes the default shift_age and shift_size to the logger" do
        expect(logger.device.options[:shift_age]).to eq 0
        expect(logger.device.options[:shift_size]).to eq 1048576
      end

      it "passes all other config.lumberjack values as options to the logger" do
        config.lumberjack.format = :json
        expect(logger.device.options[:format]).to eq :json
      end
    end
  end

  describe ".set_standard_streams_to_loggers!" do
    let(:logger) { ActiveSupport::BroadcastLogger.new(Lumberjack::Logger.new(:test)) }
    let!(:original_stdout) { $stdout }
    let!(:original_stderr) { $stderr }

    after do
      # Always restore original streams after each test
      $stdout = original_stdout
      $stderr = original_stderr
    end

    it "redirects $stdout and $stderr to logger streams when config.lumberjack.log_rake_tasks is true" do
      config.lumberjack.log_rake_tasks = true
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to_not eq(original_stdout)
      expect($stderr).to_not eq(original_stderr)
      expect($stdout).to be_a(Lumberjack::IOCompatibility)
      expect($stderr).to be_a(Lumberjack::IOCompatibility)
    end

    it "does not redirect standard streams when config.lumberjack is nil" do
      config.lumberjack = nil
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to eq(original_stdout)
      expect($stderr).to eq(original_stderr)
    end

    it "does not redirect standard streams when config.lumberjack.log_rake_tasks is not true" do
      config.lumberjack.log_rake_tasks = nil
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to eq(original_stdout)
      expect($stderr).to eq(original_stderr)
    end

    it "does not redirect standard streams when Rails.logger is not a lumberjack logger" do
      logger = ActiveSupport::BroadcastLogger.new(Logger.new(File::NULL))
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to eq(original_stdout)
      expect($stderr).to eq(original_stderr)
    end
  end
rescue LoadError
  skip "Rails is not available"
end
