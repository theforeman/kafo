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
    let(:logger) { DummyLogger.new }

    describe "#register_pre" do
      before { hooking.register_pre(:no1) { |kafo| 'got executed' } }

      let(:pre_hooks) { hooking.hooks[:pre] }
      specify { pre_hooks.keys.must_include(:no1) }

      let(:pre_hook_no1) { pre_hooks[:no1] }
      specify { pre_hook_no1.call.must_equal 'got executed' }
    end

    describe "#register_post" do
      before { hooking.register_post(:no1) { |kafo| 'got executed' } }

      let(:post_hooks) { hooking.hooks[:post] }
      specify { post_hooks.keys.must_include(:no1) }

      let(:post_hook_no1) { post_hooks[:no1] }
      specify { post_hook_no1.call.must_equal 'got executed' }
    end

    describe "#execute" do
      before do
        KafoConfigure.logger = logger
        hooking.register_pre(:no1) { |kafo| logger.error 's1' }
        hooking.register_pre(:no2) { |kafo| logger.error 's2' }
      end

      describe "#execute(:pre)" do
        before { hooking.execute(:pre); logger.rewind }
        specify { logger.error.read.must_include 's1' }
        specify { logger.error.read.must_include 's2' }
      end

      describe "#execute(:post)" do
        before { hooking.execute(:post); logger.rewind }
        specify { logger.error.read.must_be_empty }
      end
    end
  end
end
