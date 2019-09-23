require 'test_helper'

module Kafo
  describe PuppetModule do
    before do
      KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
    end

    let(:parser) { TestParser.new(BASIC_MANIFEST) }
    let(:mod) { PuppetModule.new 'puppet', parser }

    describe "#enabled?" do
      specify { mod.enabled?.must_equal true }
    end

    describe "#disable" do
      before { mod.disable }
      specify { mod.enabled?.must_equal false }
    end

    describe "#enable" do
      before { mod.disable; mod.enable }
      specify { mod.enabled?.must_equal true }
    end

    # Uses default Puppet autoloader locations
    let(:plugin1_mod) { PuppetModule.new 'foreman::plugin::default_hostgroup', parser }
    # BASIC_CONFIGURATION has mapping configured for this module
    let(:plugin2_mod) { PuppetModule.new 'foreman::plugin::chef', parser }
    # BASIC_CONFIGURATION has mapping configured for this module
    let(:certs_mod) { PuppetModule.new 'certs', parser }

    describe "#name" do
      specify { mod.name.must_equal 'puppet' }
      specify { plugin1_mod.name.must_equal 'foreman_plugin_default_hostgroup' }
      specify { plugin2_mod.name.must_equal 'foreman_plugin_chef' }
      specify { certs_mod.name.must_equal 'certs' }
    end

    describe "#dir_name" do
      specify { mod.dir_name.must_equal 'puppet' }
      specify { plugin1_mod.dir_name.must_equal 'foreman' }
      specify { plugin2_mod.dir_name.must_equal 'custom' }
      specify { certs_mod.dir_name.must_equal 'certificates' }
    end

    describe "#manifest_name" do
      specify { mod.manifest_name.must_equal 'init' }
      specify { plugin1_mod.manifest_name.must_equal 'plugin/default_hostgroup' }
      specify { plugin2_mod.manifest_name.must_equal 'plugin/custom_chef' }
      specify { certs_mod.manifest_name.must_equal 'foreman' }
    end

    describe "#class_name" do
      specify { mod.class_name.must_equal 'puppet' }
      specify { plugin1_mod.class_name.must_equal 'foreman::plugin::default_hostgroup' }
      specify { plugin2_mod.class_name.must_equal 'custom::plugin::custom_chef' }
      specify { certs_mod.class_name.must_equal 'certificates::foreman' }
    end

    describe "#manifest_path" do
      specify { mod.manifest_path.must_match %r"test/fixtures/modules/puppet/manifests/init\.pp$" }
      specify { plugin1_mod.manifest_path.must_match %r"test/fixtures/modules/foreman/manifests/plugin/default_hostgroup\.pp$" }
      specify { plugin2_mod.manifest_path.must_match %r"test/fixtures/modules/custom/manifests/plugin/custom_chef\.pp$" }
      specify { certs_mod.manifest_path.must_match %r"test/fixtures/modules/certificates/manifests/foreman\.pp$" }
    end

    describe "#params_path" do
      specify { mod.params_path.must_equal 'puppet/manifests/params.pp' }
      specify { plugin1_mod.params_path.must_equal 'foreman/manifests/plugin/default_hostgroup/params.pp' }
      specify { plugin2_mod.params_path.must_equal 'custom/plugin/chef/params.pp' }
      specify { certs_mod.params_path.must_equal 'certificates/manifests/foreman::params.pp' }
    end

    describe "#params_class_name" do
      specify { mod.params_class_name.must_equal 'params' }
      specify { plugin1_mod.params_class_name.must_equal 'plugin::default_hostgroup::params' }
      specify { plugin2_mod.params_class_name.must_equal 'params' }
      specify { certs_mod.params_class_name.must_equal 'foreman::params' }
    end

    describe "#raw_data" do
      it "returns data from parser" do
        mod.parse
        mod.raw_data.must_equal parser.parse(mod.manifest_path)
      end
    end

    let(:parsed) { mod.parse }

    describe "#parse(builder)" do
      describe "without documentation" do
        before do
          KafoConfigure.config.app[:ignore_undocumented] = true
        end

        let(:mod) { PuppetModule.new 'puppet', TestParser.new(NO_DOC_MANIFEST) }
        let(:docs) { parsed.params.map(&:doc) }
        specify { docs.each { |doc| assert_nil doc } }
      end

      describe "with not ignoring docs inconsitency" do
        before do
          KafoConfigure.config.app[:ignore_undocumented] = false
        end

        describe "undocumented params" do
          it "does throw an error" do
            KafoConfigure.stub(:exit, 'expected to exit') do
              mod.parse.must_equal 'expected to exit'
            end
          end
        end
      end

      describe "with parser cache" do
        before do
          KafoConfigure.config.app[:parser_cache_path] = ParserCacheFactory.build(
            {:files => {"puppet" => {:data => {:parameters => [], :groups => []}}}}
          ).path
          @@parsed_cache_with_cache ||= parsed
        end

        specify { @@parsed_cache_with_cache.raw_data[:parameters].must_equal [] }
        specify { @@parsed_cache_with_cache.raw_data[:groups].must_equal [] }
      end

      describe "with nil parser and no cache" do
        let(:parser) { nil }
        specify { Proc.new { parsed }.must_raise ParserError }
      end

      describe "without :none parser and no cache" do
        let(:parser) { :none }
        specify { Proc.new { parsed }.must_raise ParserError }
      end

      describe "with groups" do
        before { @@parsed_cache_with_groups ||= parsed }
        let(:groups) { @@parsed_cache_with_groups.groups.map(&:name) }
        specify { groups.must_include('Parameters') }
        specify { groups.must_include('Advanced parameters') }
        specify { groups.must_include('Extra parameters') }
        specify { groups.wont_include('MySQL') }
        specify { groups.wont_include('Sqlite') }
      end

      describe "parses parameter names" do
        before { @@parsed_cache_parameter_names ||= parsed }
        let(:param_names) { @@parsed_cache_parameter_names.params.map(&:name) }
        specify { param_names.must_include('version') }
        specify { param_names.must_include('debug') }
        specify { param_names.must_include('remote') }
        specify { param_names.must_include('file') }
        specify { param_names.must_include('m_i_a') }
      end
    end

    describe "#primary_parameter_group" do
      before { @@parsed_cache_primary ||= parsed }
      let(:primary_params) { @@parsed_cache_primary.primary_parameter_group.params.map(&:name) }
      specify { primary_params.must_include('version') }
      specify { primary_params.must_include('undef') }
      specify { primary_params.must_include('multiline') }
      specify { primary_params.must_include('typed') }
      specify { primary_params.wont_include('documented') }
      specify { primary_params.wont_include('debug') }
      specify { primary_params.wont_include('remote') }

      let(:other_groups) { parsed.other_parameter_groups }
      let(:other_groups_names) { other_groups.map(&:name) }
      specify { other_groups_names.must_include('Advanced parameters') }
      specify { other_groups_names.must_include('Extra parameters') }

      let(:advanced_group) { other_groups.detect { |g| g.name == 'Advanced parameters' } }
      specify { advanced_group.children.must_be_empty }
      let(:advanced_params) { advanced_group.params.map(&:name) }
      specify { advanced_params.must_include('debug') }
      specify { advanced_params.must_include('db_type') }
      specify { advanced_params.must_include('remote') }
      specify { advanced_params.must_include('file') }
      specify { advanced_params.wont_include('log_level') }

      describe "manifest without primary group" do
        let(:mod_wo_prim) { @@mod_wo_prim ||= PuppetModule.new('puppet', TestParser.new(MANIFEST_WITHOUT_PRIMARY_GROUP)).parse }
        let(:primary_group) { mod_wo_prim.primary_parameter_group }
        specify { primary_group.params.must_be_empty }
        let(:children_group_names) { primary_group.children.map(&:name) }
        specify { children_group_names.must_include 'Basic parameters:' }
        specify { children_group_names.must_include 'Advanced parameters:' }
      end

      describe "manifest without any group" do
        let(:mod_wo_any) { @@mod_wo_any ||= PuppetModule.new('puppet', TestParser.new(MANIFEST_WITHOUT_ANY_GROUP)).parse }
        let(:primary_group) { mod_wo_any.primary_parameter_group }
        let(:primary_params) { primary_group.params }
        specify { primary_params.wont_be_empty }
        let(:primary_param_names) { primary_params.map(&:name) }
        specify { primary_param_names.must_include 'version' }
        specify { primary_param_names.must_include 'documented' }
        specify { primary_group.children.must_be_empty }
      end
    end

    describe "#params_hash" do
      before { @@parsed_cache_params_hash ||= parsed }
      let(:params_hash) { @@parsed_cache_params_hash.params_hash }
      let(:keys) { params_hash.keys }
      specify { keys.must_include 'version' }
      specify { keys.must_include 'undocumented' }
      specify { keys.must_include 'undef' }
      specify { keys.must_include 'multiline' }
      specify { keys.must_include 'typed' }
      specify { keys.must_include 'debug' }
      specify { keys.must_include 'db_type' }
      specify { keys.must_include 'remote' }
      specify { keys.must_include 'file' }
      specify { keys.must_include 'm_i_a' }
      specify { keys.wont_include 'documented' }

      specify { params_hash['version'].must_equal '1.0' }
      specify { assert_nil params_hash['undef'] }
    end

    describe "#<=>" do
      let(:a) { PuppetModule.new('a') }
      let(:b) { PuppetModule.new('b') }
      let(:c) { PuppetModule.new('c') }
      let(:d) { PuppetModule.new('d') }
      let(:sorted) { [a, b, c, d] }
      let(:unsorted_1) { [a, c, b, d] }
      let(:unsorted_2) { [d, b, c, a] }
      let(:unsorted_3) { [a, b, d, c] }

      specify { unsorted_1.sort.must_equal sorted }
      specify { unsorted_2.sort.must_equal sorted }
      specify { unsorted_3.sort.must_equal sorted }
    end

  end
end
