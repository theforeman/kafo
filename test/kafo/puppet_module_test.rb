require 'test_helper'

module Kafo
  describe PuppetModule do
    before do
      KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
    end

    let(:mod) { PuppetModule.new 'puppet', TestParser.new(BASIC_MANIFEST) }

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

    # BASIC_CONFIGURATION has mapping configured for this module
    let(:plugin1_mod) { PuppetModule.new 'foreman::plugin::default_hostgroup', TestParser.new(BASIC_MANIFEST) }
    let(:plugin2_mod) { PuppetModule.new 'foreman::plugin::chef', TestParser.new(BASIC_MANIFEST) }

    describe "#dir_name" do
      specify { mod.dir_name.must_equal 'puppet' }
      specify { plugin1_mod.dir_name.must_equal 'foreman' }
    end

    describe "#manifest_name" do
      specify { mod.manifest_name.must_equal 'init' }
      specify { plugin1_mod.manifest_name.must_equal 'plugin/default_hostgroup' }
    end

    describe "#class_name" do
      specify { mod.class_name.must_equal 'puppet' }
      specify { plugin1_mod.class_name.must_equal 'foreman::plugin::default_hostgroup' }
    end

    describe "#manifest_path" do
      specify { mod.manifest_path.must_equal 'test/fixtures/modules/puppet/manifests/init.pp' }
      specify { plugin1_mod.manifest_path.must_equal 'test/fixtures/modules/foreman/manifests/plugin/default_hostgroup.pp' }
    end

    describe "#params_path" do
      specify { mod.params_path.must_equal 'puppet/manifests/params.pp' }
      specify { plugin1_mod.params_path.must_equal 'foreman/manifests/plugin/default_hostgroup/params.pp' }
    end

    let(:parsed) { mod.parse }

    describe "#parse(builder)" do
      describe "without documentation" do
        before do
          KafoConfigure.config.app[:ignore_undocumented] = true
        end

        let(:mod) { PuppetModule.new 'puppet', TestParser.new(NO_DOC_MANIFEST) }
        let(:docs) { parsed.params.map(&:doc) }
        specify { docs.each { |doc| doc.must_be_nil } }
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

      let(:groups) { parsed.groups.map(&:name) }
      specify { groups.must_include('Parameters') }
      specify { groups.must_include('Advanced parameters') }
      specify { groups.must_include('Extra parameters') }
      specify { groups.wont_include('MySQL') }
      specify { groups.wont_include('Sqlite') }

      let(:param_names) { parsed.params.map(&:name) }
      specify { param_names.must_include('version') }
      specify { param_names.must_include('debug') }
      specify { param_names.must_include('remote') }
      specify { param_names.must_include('file') }
      specify { param_names.must_include('m_i_a') }
    end

    describe "#primary_parameter_group" do
      let(:primary_params) { parsed.primary_parameter_group.params.map(&:name) }
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
        let(:mod_wo_prim) { PuppetModule.new('puppet', TestParser.new(MANIFEST_WITHOUT_PRIMARY_GROUP)).parse }
        let(:primary_group) { mod_wo_prim.primary_parameter_group }
        specify { primary_group.params.must_be_empty }
        let(:children_group_names) { primary_group.children.map(&:name) }
        specify { children_group_names.must_include 'Basic parameters:' }
        specify { children_group_names.must_include 'Advanced parameters:' }
      end

      describe "manifest without any group" do
        let(:mod_wo_any) { PuppetModule.new('puppet', TestParser.new(MANIFEST_WITHOUT_ANY_GROUP)).parse }
        let(:primary_group) { mod_wo_any.primary_parameter_group }
        let(:primary_params) { primary_group.params }
        specify { primary_params.wont_be_empty }
        let(:primary_param_names) { primary_params.map(&:name) }
        specify { primary_param_names.must_include 'version' }
        specify { primary_param_names.must_include 'documented' }
        specify { primary_group.children.must_be_empty }
      end
    end

    describe "#validations" do
      let(:all_validations) { parsed.validations }
      specify { all_validations.size.must_be :>, 0 }

      let(:undocumented_param) { Params::String.new(nil, 'undocumented') }
      let(:undocumented_validations) { parsed.validations(undocumented_param) }
      specify { undocumented_validations.wont_be_empty }
      let(:string_validation_of_undocumented) { undocumented_validations.first }
      specify { string_validation_of_undocumented.name.must_equal 'validate_string' }
      specify { all_validations.must_include string_validation_of_undocumented }

      # we don't support validations in nested block (conditions)
      let(:undef_param) { Params::String.new(nil, 'undef') }
      let(:undef_validations) { parsed.validations(undef_param) }
      specify { undef_validations.must_be_empty }
    end

    describe "#params_hash" do
      let(:params_hash) { parsed.params_hash }
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
      specify { params_hash['undef'].must_equal :undef }
      specify { params_hash['typed'].must_equal true }
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
