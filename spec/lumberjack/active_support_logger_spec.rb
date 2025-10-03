require "spec_helper"

RSpec.describe "ActiveSupport::Logger compatibility" do
  describe "logger_outputs_to?" do
    it "detects the underlying stream from a Writer device" do
      stream = StringIO.new
      device = Lumberjack::Device::Writer.new(stream)
      logger = Lumberjack::Logger.new(device)
      expect(ActiveSupport::Logger.logger_outputs_to?(logger, stream)).to be true
      expect(ActiveSupport::Logger.logger_outputs_to?(logger, StringIO.new)).to be false
    end

    it "detects the underlying stream from a LogFile device" do
      stream = StringIO.new
      device = Lumberjack::Device::LogFile.new(stream)
      logger = Lumberjack::Logger.new(device)
      expect(ActiveSupport::Logger.logger_outputs_to?(logger, stream)).to be true
      expect(ActiveSupport::Logger.logger_outputs_to?(logger, StringIO.new)).to be false
    end
  end
end
