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

      let(:stdout) { StringIO.new }
      let(:builder) { HelpBuilders::Advanced.new(params) }

      before { builder.instance_variable_set '@out', stdout }

      # note that these test do not preserve any order
      describe "#add_list" do
        describe "multi group output" do
          before { builder.add_list('Options', clamp_definitions) }
          let(:output) { builder.string }
          specify { _(output).must_include 'Options' }
          specify { _(output).must_include '= Generic:' }
          specify { _(output).must_include '--no-colors' }
          specify { _(output).must_include 'app wide argument, not a parameter' }
          specify { _(output).must_include '= Module puppet:' }
          specify { _(output).must_include '== Basic' }
          specify { _(output).must_include '--puppet-version' }
          specify { _(output).must_include 'version parameter' }
          specify { _(output).must_include '--reset-puppet-version' }
          specify { _(output).must_include 'reset puppet-version' }
          specify { _(output).must_include '== Advanced' }
          specify { _(output).must_include '--puppet-server' }
          specify { _(output).must_include 'enable puppetmaster server' }
          specify { _(output).must_include '--puppet-port' }
          specify { _(output).must_include 'puppetmaster port' }
        end

        describe "single group output" do
          before { builder.add_list('Options', clamp_definitions[4..6]) }
          let(:output) { builder.string }
          specify { _(output).must_include 'Options' }
          specify { _(output).must_include '= Generic:' }
          specify { _(output).must_include '--no-colors' }
          specify { _(output).must_include 'app wide argument, not a parameter' }
          specify { _(output).must_include '= Module puppet:' }
          specify { _(output).wont_include '== Basic' }
          specify { _(output).wont_include '== Advanced' }
          specify { _(output).must_include '--puppet-port' }
          specify { _(output).must_include 'puppetmaster port' }
          specify { _(output).must_include '--reset-puppet-port' }
          specify { _(output).must_include 'reset puppet-port' }
        end

        describe "no group" do
          before { builder.add_list('Options', clamp_definitions[6..6]) }
          let(:output) { builder.string }
          specify { _(output).must_include 'Options' }
          specify { _(output).must_include '= Generic:' }
          specify { _(output).must_include '--no-colors' }
          specify { _(output).must_include 'app wide argument, not a parameter' }
          specify { _(output).wont_include '= Module puppet:' }
          specify { _(output).wont_include '== Basic' }
          specify { _(output).wont_include '== Advanced' }
          specify { _(output).wont_include '--puppet-version' }
          specify { _(output).wont_include '--reset-puppet-version' }
          specify { _(output).wont_include '--puppet-port' }
          specify { _(output).wont_include '--reset-puppet-port' }
        end
      end
    end

    describe "advanced with visible advanced" do
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
            Param.new(OpenStruct.new(:name => 'apache'), 'port', 'Integer').tap do |p|
              p.doc    = "apache port"
              p.groups = []
            end,
        ]
      end

      let(:clamp_definitions) do
        [
            OpenStruct.new(:help => ['--puppet-version', 'version parameter (current: "foo")']),
            OpenStruct.new(:help => ['--reset-puppet-version', 'Reset version to the default value (default: "bar")']),
            OpenStruct.new(:help => ['--puppet-server', 'enable puppetmaster server (current: "foo")']),
            OpenStruct.new(:help => ['--reset-puppet-server', 'Reset server to the default value (default: "bar")']),
            OpenStruct.new(:help => ['--puppet-port', 'puppetmaster port (current: "foo")']),
            OpenStruct.new(:help => ['--reset-puppet-port', 'Reset port to the default value (default: "bar")']),
            OpenStruct.new(:help => ['--help', 'app wide argument, not advanced'], :attribute_name => 'help'),
            OpenStruct.new(:help => ['--no-colors', 'app wide argument, not a parameter'], :attribute_name => 'no_colors', :advanced? => true),
            OpenStruct.new(:help => ['--apache-port', 'apache module parameter (current: "foo")']),
            OpenStruct.new(:help => ['--reset-apache-port', 'Reset port to the default value (default: "bar")']),
        ]
      end

      let(:stdout) { StringIO.new }
      let(:builder) do
        HelpBuilders::Advanced.new(params)
      end

      before { builder.instance_variable_set '@out', stdout }

      # note that these test do not preserve any order
      describe "#add_list" do
        before { builder.add_list('Options', clamp_definitions) }

        let(:output) { builder.string }

        specify { _(output).must_include 'Options' }
        specify { _(output).must_include '= Generic:' }
        specify { _(output).must_include '--no-colors' }
        specify { _(output).must_include 'app wide argument, not a parameter' }
        specify { _(output).must_include '= Module puppet:' }
        specify { _(output).must_include '--puppet-version' }
        specify { _(output).must_include 'version parameter' }
        specify { _(output).must_include '--reset-puppet-version' }
        specify { _(output).must_include 'Reset version to the default value (default: "bar")' }
        specify { _(output).must_include '--puppet-server' }
        specify { _(output).must_include '--reset-puppet-server' }
        specify { _(output).must_include 'Reset server to the default value (default: "bar")' }
        specify { _(output).must_include '--puppet-port' }
        specify { _(output).must_include 'puppetmaster port' }
        specify { _(output).must_include '--reset-puppet-port' }
        specify { _(output).must_include 'Reset port to the default value (default: "bar")' }
        specify { _(output).must_include 'Basic' }
        specify { _(output).must_include 'Advanced' }
        specify { _(output).must_match(/Generic.*Module apache.*Module puppet/m) }
      end
    end
  end
end
