require 'test_helper'

module Kafo
  describe Logger do

    it "uses root logger if no name is supplied" do
      _(Logger.new.logger.name).must_equal 'root'
    end

    it "creates a logger from the name supplied" do
      _(Logger.new('test').logger.name).must_equal 'test'
    end

    describe "buffering with verbose mode" do
      before do
        ::Logging.logger.root.appenders = []
        @logger = Logger.new
        @logger.debug "one"
        @logger.error "two"
        @logger.info "three"
      end

      it "add log messages to buffer" do
        _(Logging.buffer.length).must_equal 3
      end
    end

    describe "dumps buffer with verbose mode" do
      before do
        @logger = Logger.new
        @logger.debug "one"
        @logger.error "two"
        @logger.info "three"
        Logging.setup_verbose
        @logger.debug 'four'
      end

      it "dumps the buffer after verbose is set" do
        _(Logging.buffer.length).must_equal 0
      end
    end

  end
end
