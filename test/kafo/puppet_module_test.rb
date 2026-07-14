require 'test_helper'

module Kafo
  describe PuppetModule do
    let(:config) { Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path) }
    let(:module_name) { 'testing' }
    let(:manifest) { BASIC_MANIFEST }
    let(:parser) { TestParser.new(manifest) }
    let(:mod) { PuppetModule.new(module_name, configuration: config) }

    before do
      config.instance_variable_set(:@parser, parser)
    end

    describe "#enabled?" do
      specify { _(mod.enabled?).must_equal true }
    end

    describe "#disable" do
      before { mod.disable }
      specify { _(mod.enabled?).must_equal false }
    end

    describe "#enable" do
      before { mod.disable; mod.enable }
      specify { _(mod.enabled?).must_equal true }
    end

    # Uses default Puppet autoloader locations
    let(:plugin1_mod) { PuppetModule.new('foreman::plugin::default_hostgroup', configuration: config) }
    # BASIC_CONFIGURATION has mapping configured for this module
    let(:plugin2_mod) { PuppetModule.new('foreman::plugin::chef', configuration: config) }
    # BASIC_CONFIGURATION has mapping configured for this module
    let(:certs_mod) { PuppetModule.new('certs', configuration: config) }

    describe "#name" do
      specify { _(mod.name).must_equal 'testing' }
      specify { _(plugin1_mod.name).must_equal 'foreman_plugin_default_hostgroup' }
      specify { _(plugin2_mod.name).must_equal 'foreman_plugin_chef' }
      specify { _(certs_mod.name).must_equal 'certs' }
    end

    describe "#dir_name" do
      specify { _(mod.dir_name).must_equal 'testing' }
      specify { _(plugin1_mod.dir_name).must_equal 'foreman' }
      specify { _(plugin2_mod.dir_name).must_equal 'custom' }
      specify { _(certs_mod.dir_name).must_equal 'certificates' }
    end

    describe "#manifest_name" do
      specify { _(mod.manifest_name).must_equal 'init' }
      specify { _(plugin1_mod.manifest_name).must_equal 'plugin/default_hostgroup' }
      specify { _(plugin2_mod.manifest_name).must_equal 'plugin/custom_chef' }
      specify { _(certs_mod.manifest_name).must_equal 'foreman' }
    end

    describe "#class_name" do
      specify { _(mod.class_name).must_equal 'testing' }
      specify { _(plugin1_mod.class_name).must_equal 'foreman::plugin::default_hostgroup' }
      specify { _(plugin2_mod.class_name).must_equal 'custom::plugin::custom_chef' }
      specify { _(certs_mod.class_name).must_equal 'certificates::foreman' }
    end

    describe "#manifest_path" do
      specify { _(mod.manifest_path).must_match %r"test/fixtures/modules/testing/manifests/init\.pp$" }
      specify { _(plugin1_mod.manifest_path).must_match %r"test/fixtures/modules/foreman/manifests/plugin/default_hostgroup\.pp$" }
      specify { _(plugin2_mod.manifest_path).must_match %r"test/fixtures/modules/custom/manifests/plugin/custom_chef\.pp$" }
      specify { _(certs_mod.manifest_path).must_match %r"test/fixtures/modules/certificates/manifests/foreman\.pp$" }
    end

    describe "#params_path" do
      specify { _(mod.params_path).must_equal 'testing/manifests/params.pp' }
      specify { _(plugin1_mod.params_path).must_equal 'foreman/manifests/plugin/default_hostgroup/params.pp' }
      specify { _(plugin2_mod.params_path).must_equal 'custom/plugin/chef/params.pp' }
      specify { _(certs_mod.params_path).must_equal 'certificates/manifests/foreman/params.pp' }
    end

    describe "#params_class_name" do
      specify { _(mod.params_class_name).must_equal 'params' }
      specify { _(plugin1_mod.params_class_name).must_equal 'plugin::default_hostgroup::params' }
      specify { _(plugin2_mod.params_class_name).must_equal 'params' }
      specify { _(certs_mod.params_class_name).must_equal 'foreman::params' }
    end

    describe "#raw_data" do
      before { mod.parse }
      subject { mod.raw_data }

      it "returns data from parser" do
        _(subject).must_equal parser.parse(mod.manifest_path)
      end
    end

    describe "#parse" do
      subject { mod.parse }

      describe "without documentation" do
        let(:manifest) { NO_DOC_MANIFEST }
        before do
          config.app[:ignore_undocumented] = true
        end

        specify { subject.params.map(&:doc).each { |doc| _(doc).must_be_nil } }
      end

      describe "with not ignoring docs inconsitency" do
        before do
          config.app[:ignore_undocumented] = false
        end

        describe "undocumented params" do
          it "does throw an error" do
            KafoConfigure.stub(:exit, 'expected to exit') do
              _(subject).must_equal 'expected to exit'
            end
          end
        end
      end
    end

    describe '#groups' do
      before { mod.parse }
      subject { mod.groups }

      specify 'names' do
        _(subject.map(&:name)).must_equal(['Parameters', 'Advanced parameters', 'Extra parameters'])
      end
    end

    describe "#primary_parameter_group" do
      before { mod.parse }
      subject { mod.primary_parameter_group }

      specify 'params' do
        _(subject.params.map(&:name)).must_equal(['version', 'undef', 'multiline', 'typed', 'multivalue'])
      end

      specify 'children' do
        _(subject.children).must_be_empty
      end

      describe "manifest without primary group" do
        let(:module_name) { 'testing2' }
        let(:manifest) { MANIFEST_WITHOUT_PRIMARY_GROUP }

        specify 'params' do
          _(subject.params).must_be_empty
        end

        specify 'children' do
          _(subject.children.map(&:name)).must_equal(['Basic parameters:', 'Advanced parameters:'])
        end
      end

      describe "manifest without any group" do
        let(:module_name) { 'testing3' }
        let(:manifest) { MANIFEST_WITHOUT_ANY_GROUP }

        specify 'params' do
          _(subject.params.map(&:name)).must_equal(['version', 'documented'])
        end

        specify 'children' do
          _(subject.children).must_be_empty
        end
      end
    end

    describe '#other_parameter_groups' do
      before { mod.parse }
      subject { mod.other_parameter_groups }

      specify 'names' do
        _(subject.map(&:name)).must_equal(['Advanced parameters', 'Extra parameters'])
      end

      describe 'advanced group' do
        subject { mod.other_parameter_groups.detect { |g| g.name == 'Advanced parameters' } }

        specify { _(subject.children).must_be_empty }
        it 'param names' do
          _(subject.params.map(&:name)).must_equal(['debug', 'db_type', 'remote', 'server', 'username', 'pool_size', 'file'])
        end
      end
    end

    describe "#params" do
      before { mod.parse }
      subject { mod.params }

      specify 'names' do
        _(subject.map(&:name)).must_equal(['version', 'undocumented', 'undef', 'multiline', 'typed', 'multivalue', 'debug', 'db_type', 'remote', 'server', 'username', 'pool_size', 'file', 'm_i_a'])
      end
    end

    describe "#params_hash" do
      before { mod.parse }
      subject { mod.params_hash }

      specify 'keys' do
        _(subject.keys).must_equal(['version', 'undocumented', 'undef', 'multiline', 'typed', 'multivalue', 'debug', 'db_type', 'remote', 'server', 'username', 'pool_size', 'file', 'm_i_a'])
      end
      specify { _(subject['version']).must_equal '1.0' }
      specify { _(subject['undef']).must_be_nil }
    end

    describe "#<=>" do
      let(:a) { PuppetModule.new('a', configuration: config) }
      let(:b) { PuppetModule.new('b', configuration: config) }
      let(:c) { PuppetModule.new('c', configuration: config) }
      let(:d) { PuppetModule.new('d', configuration: config) }
      let(:sorted) { [a, b, c, d] }

      specify { _([a, c, b, d].sort).must_equal sorted }
      specify { _([d, b, c, a].sort).must_equal sorted }
      specify { _([a, b, d, c].sort).must_equal sorted }
    end

  end
end
