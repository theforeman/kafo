require 'test_helper'

describe PuppetModule do
  before do
    KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
  end

  let(:mod) { PuppetModule.new 'puppet', TestParser }

  describe "#enabled?" do
    it { mod.enabled?.must_equal true }
  end

  describe "#disable" do
    before { mod.disable }
    it { mod.enabled?.must_equal false }
  end

  describe "#enable" do
    before { mod.disable; mod.enable }
    it { mod.enabled?.must_equal true }
  end

  let(:parsed) { mod.parse }

  describe "#parse(builder)" do
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
    it { groups.must_include('Parameters') }
    it { groups.must_include('Advanced parameters') }
    it { groups.must_include('Extra parameters') }
    it { groups.wont_include('MySQL') }
    it { groups.wont_include('Sqlite') }

    let(:param_names) { parsed.params.map(&:name) }
    it { param_names.must_include('version') }
    it { param_names.must_include('debug') }
    it { param_names.must_include('remote') }
    it { param_names.must_include('file') }
    it { param_names.must_include('m_i_a') }
  end

  describe "#primary_parameter_group" do
    let(:primary_params) { parsed.primary_parameter_group.params.map(&:name) } # documented causes troubles! it's nil!
    it { primary_params.must_include('version') }
    it { primary_params.must_include('undef') }
    it { primary_params.must_include('multiline') }
    it { primary_params.must_include('typed') }
    it { primary_params.wont_include('documented') }
    it { primary_params.wont_include('debug') }
    it { primary_params.wont_include('remote') }

    let(:other_groups) { parsed.other_parameter_groups }
    let(:other_groups_names) { other_groups.map(&:name) }
    it { other_groups_names.must_include('Advanced parameters') }
    it { other_groups_names.must_include('Extra parameters') }

    let(:advanced_group) { other_groups.detect { |g| g.name == 'Advanced parameters' } }
    it { advanced_group.children.must_be_empty }
    let(:advanced_params) { advanced_group.params.map(&:name) }
    it { advanced_params.must_include('debug') }
    it { advanced_params.must_include('db_type') }
    it { advanced_params.must_include('remote') }
    it { advanced_params.must_include('file') }
    it { advanced_params.wont_include('log_level') }
  end

  describe "#validations" do
    let(:all_validations) { parsed.validations }
    it { all_validations.size.must_be :>, 0 }

    let(:undocumented_param) { Params::String.new(nil, 'undocumented') }
    let(:undocumented_validations) { parsed.validations(undocumented_param) }
    it { undocumented_validations.wont_be_empty }
    let(:string_validation_of_undocumented) { undocumented_validations.first }
    it { string_validation_of_undocumented.name.must_equal 'validate_string' }
    it { all_validations.must_include string_validation_of_undocumented }

    # we don't support validations in nested block (conditions)
    let(:undef_param) { Params::String.new(nil, 'undef') }
    let(:undef_validations) { parsed.validations(undef_param) }
    it { undef_validations.must_be_empty }
  end

  describe "#params_hash" do
    let(:params_hash) { parsed.params_hash }
    let(:keys) { params_hash.keys }
    it { keys.must_include 'version' }
    it { keys.must_include 'undocumented' }
    it { keys.must_include 'undef' }
    it { keys.must_include 'multiline' }
    it { keys.must_include 'typed' }
    it { keys.must_include 'debug' }
    it { keys.must_include 'db_type' }
    it { keys.must_include 'remote' }
    it { keys.must_include 'file' }
    it { keys.must_include 'm_i_a' }
    it { keys.wont_include 'documented' }

    it { params_hash['version'].must_equal '1.0' }
    it { params_hash['undef'].must_equal :undef }
    it { params_hash['typed'].must_equal true }
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

    it { unsorted_1.sort.must_equal sorted }
    it { unsorted_2.sort.must_equal sorted }
    it { unsorted_3.sort.must_equal sorted }
  end

end
