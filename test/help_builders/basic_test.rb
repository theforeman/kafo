require 'test_helper'

describe HelpBuilders::Basic do
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
  let(:builder) { HelpBuilders::Basic.new(params) }

  before { builder.instance_variable_set '@out', stdout }

  # note that these test do not preserve any order
  describe "#add_list" do
    before { builder.add_list('Options', clamp_definitions) }
    let(:output) { stdout.rewind; stdout.read }
    it { output.must_include 'Options' }
    it { output.must_include '= Generic:' }
    it { output.must_include '--no-colors' }
    it { output.must_include 'app wide argument, not a parameter' }
    it { output.must_include '= Module puppet:' }
    it { output.must_include '--puppet-version' }
    it { output.must_include 'version parameter' }
    it { output.wont_include '--puppet-server' }
    it { output.wont_include 'enable puppetmaster server' }
    it { output.wont_include '--puppet-port' }
    it { output.wont_include 'puppetmaster port' }
    it { output.wont_include 'Basic' }
    it { output.wont_include 'Advanced' }
  end
end
