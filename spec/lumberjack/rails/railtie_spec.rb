# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Railtie" do
  require "rails"
  require_relative "../../../lib/lumberjack/rails/railtie"

  let(:config) do
    ActiveSupport::OrderedOptions.new.tap do |cfg|
      cfg.lumberjack = ActiveSupport::OrderedOptions.new
      cfg.lumberjack.enabled = true
    end
  end

  describe ".lumberjack_logger" do
    let(:logger) { Lumberjack::Rails::Railtie.lumberjack_logger(config, nil) }

    context "when lumberjack is not configured" do
      it "returns nil if config.lumbrjack is not defined" do
        config.delete(:lumberjack)
        expect(logger).to be_nil
      end

      it "returns nil if config.lumberjack.enabled is not true" do
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
        log_file_path = File.join(Dir.tmpdir, "test.log")
        config.lumberjack.device = nil

        begin
          logger = Lumberjack::Rails::Railtie.lumberjack_logger(config, log_file_path)
          expect(logger.device).to be_a(Lumberjack::Device::LoggerFile)
          expect(logger.device.path).to eq(log_file_path)
        ensure
          FileUtils.rm_f(log_file_path)
        end
      end

      it "uses STDOUT if no device or log file is configured" do
        config.lumberjack.device = nil
        logger = Lumberjack::Rails::Railtie.lumberjack_logger(config, nil)
        expect(logger.device.send(:stream)).to equal($stdout)
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

      it "adds config.lumberjack.attributes to the logger" do
        config.lumberjack.global_attributes = {foo: "bar"}
        expect(logger.attributes).to eq("foo" => "bar")
      end

      it "adds tagged logger tags from config.log_tags" do
        config.log_tags = ["foo", "bar"]
        expect(logger.attributes).to eq("tags" => ["foo", "bar"])
      end

      it "merges config.lumberjack.attributes and config.log_tags" do
        config.lumberjack.global_attributes = {baz: "qux"}
        config.log_tags = ["foo", "bar"]
        expect(logger.attributes).to eq("baz" => "qux", "tags" => ["foo", "bar"])
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

    around do |example|
      save_stdout = $stdout
      save_stderr = $stderr
      begin
        $stdout = StringIO.new
        $stderr = StringIO.new
        example.run
      ensure
        $stdout = save_stdout
        $stderr = save_stderr
      end
    end

    it "redirects $stdout and $stderr to logger streams when config.lumberjack.log_rake_tasks is true" do
      config.lumberjack.log_rake_tasks = true
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to be_a(Lumberjack::IOCompatibility)
      expect($stderr).to be_a(Lumberjack::IOCompatibility)
    end

    it "does not redirect standard streams when config.lumberjack is nil" do
      config.lumberjack = nil
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to be_a(StringIO)
      expect($stderr).to be_a(StringIO)
    end

    it "does not redirect standard streams when config.lumberjack.log_rake_tasks is not true" do
      config.lumberjack.log_rake_tasks = nil
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to be_a(StringIO)
      expect($stderr).to be_a(StringIO)
    end

    it "does not redirect standard streams when Rails.logger is not a lumberjack logger" do
      logger = ActiveSupport::BroadcastLogger.new(Logger.new(File::NULL))
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to be_a(StringIO)
      expect($stderr).to be_a(StringIO)
    end

    it "does not redirect tty streams" do
      config.lumberjack.log_rake_tasks = true
      allow($stdout).to receive(:tty?).and_return(true)
      Lumberjack::Rails::Railtie.set_standard_streams_to_loggers!(config, logger)

      expect($stdout).to be_a(StringIO)
      expect($stderr).to be_a(Lumberjack::IOCompatibility)
    end
  end
rescue LoadError
  skip "Rails is not available"
end
