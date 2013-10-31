require 'test_helper'

describe HelpBuilders::Advanced do
  let(:params) do
    [
        Params::String.new(OpenStruct.new(:name => 'puppet'), 'version').tap do |p|
          p.doc = "version parameter"
          p.groups = []
        end,
        Params::Boolean.new(OpenStruct.new(:name => 'puppet'), 'server').tap do |p|
          p.doc = "enable puppetmaster server"
          p.groups = ["Advanced parameters:"]
        end,
        Params::Integer.new(OpenStruct.new(:name => 'puppet'), 'port').tap do |p|
          p.doc = "puppetmaster port"
          p.groups = ["Advanced parameters:"]
        end,
    ]
  end

  let(:clamp_definitions) do
    [
        OpenStruct.new(:help => ['--puppet-version', 'version parameter']),
        OpenStruct.new(:help => ['--puppet-server', 'enable puppetmaster server']),
        OpenStruct.new(:help => ['--puppet-port', 'puppetmaster port']),
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
      let(:output) { stdout.rewind; stdout.read }
      specify { output.must_include 'Options' }
      specify { output.must_include '= Generic:' }
      specify { output.must_include '--no-colors' }
      specify { output.must_include 'app wide argument, not a parameter' }
      specify { output.must_include '= Module puppet:' }
      specify { output.must_include '== Basic' }
      specify { output.must_include '--puppet-version' }
      specify { output.must_include 'version parameter' }
      specify { output.must_include '== Advanced' }
      specify { output.must_include '--puppet-server' }
      specify { output.must_include 'enable puppetmaster server' }
      specify { output.must_include '--puppet-port' }
      specify { output.must_include 'puppetmaster port' }
    end

    describe "single group output" do
      before { builder.add_list('Options', clamp_definitions[2..3]) }
      let(:output) { stdout.rewind; stdout.read }
      specify { output.must_include 'Options' }
      specify { output.must_include '= Generic:' }
      specify { output.must_include '--no-colors' }
      specify { output.must_include 'app wide argument, not a parameter' }
      specify { output.must_include '= Module puppet:' }
      specify { output.wont_include '== Basic'}
      specify { output.wont_include '== Advanced'}
      specify { output.must_include '--puppet-port' }
      specify { output.must_include 'puppetmaster port' }
    end

    describe "no group" do
      before { builder.add_list('Options', clamp_definitions[3..3]) }
      let(:output) { stdout.rewind; stdout.read }
      specify { output.must_include 'Options' }
      specify { output.must_include '= Generic:' }
      specify { output.must_include '--no-colors' }
      specify { output.must_include 'app wide argument, not a parameter' }
      specify { output.wont_include '= Module puppet:' }
      specify { output.wont_include '== Basic'}
      specify { output.wont_include '== Advanced'}
      specify { output.wont_include '--puppet-version' }
      specify { output.wont_include '--puppet-port' }
    end
  end
end
