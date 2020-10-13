require 'test_helper'
require 'tempfile'

module Kafo
  describe PuppetConfigurer do
    let(:config) { Tempfile.new('config') }
    subject { PuppetConfigurer.new(config.path) }

    describe ".initialize" do
      specify { _(subject['reports']).must_equal '' }
      specify { _(subject['other']).must_be_nil }
      specify { _(PuppetConfigurer.new(config.path, 'reports' => 'store')['reports']).must_equal 'store' }
    end

    describe "[]=" do
      specify { _(subject.tap { |s| s['reports'] = 'foo' }['reports']).must_equal 'foo' }
      specify { _(subject.tap { |s| s['noop'] = false }['noop']).must_equal false }
    end

    describe "#write_config" do
      let(:settings) { {'noop' => false} }
      subject { PuppetConfigurer.new(config.path, settings).tap { |s| s.write_config } }
      specify { _(File.exist?(subject.config_path)).must_equal true }
      specify { _(File.read(subject.config_path)).must_equal "[main]\nnoop = false\nreports = \n" }
    end
  end
end
