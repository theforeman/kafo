require 'test_helper'

module Kafo
  describe Logger do
    let(:logger) { Kafo::Logger.new }
    let(:log_device) { DummyLogger.new }

    [true, false].each do |verbose_mode|
      before { KafoConfigure.verbose = verbose_mode }

      describe "buffering with verbose #{verbose_mode}" do
        before do
          logger.debug "one"
          logger.error "two"
          Logger.loggers = [log_device]
          logger.info "three"
          log_device.rewind
        end

        it "logs messages after loggers were set" do
          _(log_device.info.read.chomp).must_equal 'three'
        end

        it "logs messages even before setup" do
          _(log_device.debug.read.chomp).must_equal 'one'
          _(log_device.error.read.chomp).must_equal 'two'
        end
      end

      describe "error buffering with verbose #{verbose_mode}" do
        before do
          Logger.loggers = [log_device]
          logger.debug 'debug'
          logger.info 'info'
          logger.warn 'warn'
          logger.error 'error'
          logger.fatal 'fatal'
          Logger.dump_errors
          log_device.rewind
        end

        it "logs error twice" do
          errors = log_device.error.read.tr("\n", '')
          _(errors).must_match(/.*error.*error.*/)

          fatals = log_device.fatal.read.tr("\n", '')
          _(fatals).must_match(/.*fatal.*fatal.*/)
        end

        it "logs normal messages just once" do
          debug = log_device.debug.read
          _(debug).wont_match(/.*debug.*debug.*/)

          info = log_device.info.read
          _(info).wont_match(/.*info.*info.*/)

          warn = log_device.warn.read
          _(warn).wont_match(/.*warn.*warn.*/)
        end
      end
    end
  end
end
