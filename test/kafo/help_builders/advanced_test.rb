require 'test_helper'

module Kafo
  module HelpBuilders
    describe Advanced do
      let(:params) do
        [
            Param.new(OpenStruct.new(:name => 'puppet'), 'version', 'String').tap do |p|
              p.doc    = "version parameter"
              p.groups = []
            end,
            Param.new(OpenStruct.new(:name => 'puppet'), 'server', 'Boolean').tap do |p|
              p.doc    = "enable puppetmaster server"
              p.groups = ["Advanced parameters:"]
            end,
            Param.new(OpenStruct.new(:name => 'puppet'), 'port', 'Integer').tap do |p|
              p.doc    = "puppetmaster port"
              p.groups = ["Advanced parameters:"]
            end,
        ]
      end

      let(:clamp_definitions) do
        [
            OpenStruct.new(:help => ['--puppet-version', 'version parameter']),
            OpenStruct.new(:help => ['--reset-puppet-version', 'reset puppet-version to default value']),
            OpenStruct.new(:help => ['--puppet-server', 'enable puppetmaster server']),
            OpenStruct.new(:help => ['--reset-puppet-server', 'reset puppet-server to default value']),
            OpenStruct.new(:help => ['--puppet-port', 'puppetmaster port']),
            OpenStruct.new(:help => ['--reset-puppet-port', 'reset puppet-port to default value']),
            OpenStruct.new(:help => ['--no-colors', 'app wide argument, not a parameter']),
        ]
      end

      let(:builder) { HelpBuilders::Advanced.new(params) }

      # note that these test do not preserve any order
      describe "#add_list" do
        describe "multi group output" do
          before { builder.add_list('Options', clamp_definitions) }
          let(:output) { builder.string }
          specify { output.must_include 'Options' }
          specify { output.must_include '= Generic:' }
          specify { output.must_include '--no-colors' }
          specify { output.must_include 'app wide argument, not a parameter' }
          specify { output.must_include '= Module puppet:' }
          specify { output.must_include '== Basic' }
          specify { output.must_include '--puppet-version' }
          specify { output.must_include 'version parameter' }
          specify { output.must_include '--reset-puppet-version' }
          specify { output.must_include 'reset puppet-version' }
          specify { output.must_include '== Advanced' }
          specify { output.must_include '--puppet-server' }
          specify { output.must_include 'enable puppetmaster server' }
          specify { output.must_include '--puppet-port' }
          specify { output.must_include 'puppetmaster port' }
        end

        describe "single group output" do
          before { builder.add_list('Options', clamp_definitions[4..6]) }
          let(:output) { builder.string }
          specify { output.must_include 'Options' }
          specify { output.must_include '= Generic:' }
          specify { output.must_include '--no-colors' }
          specify { output.must_include 'app wide argument, not a parameter' }
          specify { output.must_include '= Module puppet:' }
          specify { output.wont_include '== Basic' }
          specify { output.wont_include '== Advanced' }
          specify { output.must_include '--puppet-port' }
          specify { output.must_include 'puppetmaster port' }
          specify { output.must_include '--reset-puppet-port' }
          specify { output.must_include 'reset puppet-port' }
        end

        describe "no group" do
          before { builder.add_list('Options', clamp_definitions[6..6]) }
          let(:output) { builder.string }
          specify { output.must_include 'Options' }
          specify { output.must_include '= Generic:' }
          specify { output.must_include '--no-colors' }
          specify { output.must_include 'app wide argument, not a parameter' }
          specify { output.wont_include '= Module puppet:' }
          specify { output.wont_include '== Basic' }
          specify { output.wont_include '== Advanced' }
          specify { output.wont_include '--puppet-version' }
          specify { output.wont_include '--reset-puppet-version' }
          specify { output.wont_include '--puppet-port' }
          specify { output.wont_include '--reset-puppet-port' }
        end
      end
    end
  end
end
