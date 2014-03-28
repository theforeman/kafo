require 'test_helper'

class DummyLogger
  LEVELS = %w(error info debug)

  def initialize
    LEVELS.each { |l| instance_variable_set("@#{l}", StringIO.new) }
  end

  LEVELS.each do |level|
    define_method(level) do |*messages|
      current_level = instance_variable_get("@#{level}")
      messages.empty? ? current_level : current_level.puts(messages.first)
    end
  end

  def rewind
    LEVELS.each { |l| instance_variable_get("@#{l}").rewind }
  end
end

module Kafo
  describe Hooking do
    let(:hooking) { Hooking.new }
    let(:dummy_logger) { DummyLogger.new }

    describe "#register_pre" do
      before { hooking.register_pre(:no1) { 'got executed' } }

      let(:pre_hooks) { hooking.hooks[:pre] }
      specify { pre_hooks.keys.must_include(:no1) }

      let(:pre_hook_no1) { pre_hooks[:no1] }
      specify { pre_hook_no1.call.must_equal 'got executed' }
    end

    describe "#execute" do
      before do
        KafoConfigure.logger = dummy_logger
        hooking.kafo = OpenStruct.new(:logger => dummy_logger)
        hooking.register_pre(:no1) { logger.error 's1' }
        hooking.register_pre(:no2) { logger.error 's2' }
      end

      # it runs in HookContext context so it has access to logger
      describe "#execute(:pre)" do
        before { hooking.execute(:pre); dummy_logger.rewind }
        specify { dummy_logger.error.read.must_include 's2' }
        specify { dummy_logger.error.read.must_include 's1' }
      end

      describe "#execute(:post)" do
        before { hooking.execute(:post); dummy_logger.rewind }
        specify { dummy_logger.error.read.must_be_empty }
      end
    end
  end
end
