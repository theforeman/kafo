require 'test_helper'
require 'kafo/hiera_configurer'

module Kafo
  describe PuppetConfigurer do
    subject { PuppetConfigurer.new }

    describe ".initialize" do
      specify { subject['reports'].must_equal '' }
      specify { subject['other'].must_be_nil }
      specify { PuppetConfigurer.new('reports' => 'store')['reports'].must_equal 'store' }
    end

    describe "[]=" do
      specify { subject.tap { |s| s['reports'] = 'foo' }['reports'].must_equal 'foo' }
      specify { subject.tap { |s| s['noop'] = false }['noop'].must_equal false }
    end

    describe "#write_config" do
      let(:settings) { {'noop' => false} }
      subject { PuppetConfigurer.new(settings).tap { |s| s.write_config } }
      after { FileUtils.rm_rf(subject.config_path) }
      specify { File.exist?(subject.config_path).must_equal true }
      specify { File.read(subject.config_path).must_equal "[main]\nnoop = false\nreports = \n" }
    end
  end
end
