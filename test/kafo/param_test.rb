require 'test_helper'

module Kafo
  describe Param do
    let(:mod) { nil }
    let(:param) { Param.new(mod, 'test', 'Optional[String]') }

    let(:with_params) { param.tap { |p| p.manifest_default = '$mod::params::test' } }
    let(:with_undef) { param.tap { |p| p.manifest_default = :undef } }
    let(:with_unset) { param.tap { |p| p.manifest_default = 'UNSET' } }
    let(:with_value) { param.tap { |p| p.manifest_default = '42' } }
    let(:with_module_data) { param.tap { |p| p.default = '42' } }

    describe "#visible?" do
      describe "without condition" do
        specify { _(param).must_be :visible? }
      end

      describe "with true condition" do
        before { param.condition = 'true' }
        specify { _(param).must_be :visible? }
      end

      describe "with false condition" do
        before { param.condition = 'false' }
        specify { _(param).wont_be :visible? }
      end

      describe "with context" do
        let(:context) { [Param.new(nil, 'context', 'String').tap { |p| p.value = true }] }
        before { param.condition = '$context' }
        specify { _(param.visible?(context)).must_equal true }
      end
    end

    describe "#condition_value" do
      before { param.value = 'tester' }
      specify { _(param.condition_value).must_be_kind_of String }
    end

    describe "#default" do
      specify { _(with_params.default).must_be_nil }
      specify { _(with_params.tap { |p| p.default = 'test' }.default).must_equal 'test' }
      specify { _(with_value.default).must_equal '42' }
      specify { _(with_module_data.default).must_equal '42' }
    end

    describe "#default=" do
      specify { _(with_params.tap { |p| p.default = 'test' }.default).must_equal 'test' }
      specify { _(with_params.tap { |p| p.default = :undef }.default).must_be_nil }
      specify { _(with_params.tap { |p| p.default = 'UNSET' }.default).must_be_nil }
    end

    describe "#dump_default_needed?" do
      specify { _(with_params.dump_default_needed?).must_equal true }
      specify { _(with_undef.dump_default_needed?).must_equal false }
      specify { _(with_unset.dump_default_needed?).must_equal false }
      specify { _(with_value.dump_default_needed?).must_equal false }
      specify { _(with_module_data.dump_default_needed?).must_equal false }
    end

    describe "group" do
      it "should return empty array by default" do
        _(param.groups).must_equal []
      end

      describe "when nil was set" do
        before { param.groups = nil }
        specify { _(param.groups).must_equal [] }
      end

      describe "groups were set" do
        before { param.groups = [ ParamGroup.new('one'), ParamGroup.new('two') ] }
        let(:group_names) { param.groups.map(&:name) }
        specify { _(group_names).must_include 'one' }
        specify { _(group_names).must_include 'two' }
      end
    end

    describe "#identifier" do
      specify { _(param.identifier).must_equal 'test' }

      describe "with module" do
        let(:mod) do
          mod = MiniTest::Mock.new
          mod.expect(:identifier, 'examplemod')
          mod
        end
        specify { _(param.identifier).must_equal 'examplemod::test' }
      end
    end

    describe "#manifest_default=" do
      specify { _(with_params.tap { |p| p.manifest_default = 'test' }.manifest_default).must_equal 'test' }
      specify { _(with_params.tap { |p| p.manifest_default = :undef }.manifest_default).must_be_nil }
      specify { _(with_params.tap { |p| p.manifest_default = 'UNSET' }.manifest_default).must_be_nil }
    end

    describe "#manifest_default_params_variable" do
      specify { _(with_params.manifest_default_params_variable).must_equal 'mod::params::test' }
      specify { _(with_value.manifest_default_params_variable).must_be_nil }
      specify { _(with_undef.manifest_default_params_variable).must_be_nil }
      specify { _(with_unset.manifest_default_params_variable).must_be_nil }
    end

    describe "#valid?" do
      let(:mod) do
        MiniTest::Mock.new
      end

      describe "with correct data type" do
        specify { _(param.valid?).must_equal true }
      end

      describe "with invalid data type" do
        before { param.value = 1 }
        specify { _(param.valid?).must_equal false }
        specify { _(param.tap { |p| p.valid? }.validation_errors).must_equal ['1 is not a valid string'] }
      end

      describe "with manifest default value needing typecasting" do
        let(:param) { Param.new(mod, 'test', 'Integer') }
        before { param.manifest_default = '2' }
        specify { _(param.valid?).must_equal true }
      end

      describe "with dumped default value needing typecasting" do
        let(:param) { Param.new(mod, 'test', 'Integer') }
        before do
          param.manifest_default = '$mod::params::test'
          param.default = '2'
        end
        specify { _(param.valid?).must_equal true }
      end
    end

    describe '#set_default_from_dump' do
      specify { _(with_params.tap { |p| p.set_default_from_dump({}) }.default).must_be_nil }
      specify { _(with_params.tap { |p| p.set_default_from_dump({'mod::params::test' => '42'}) }.default).must_equal '42' }
      specify { _(with_params.tap { |p| p.set_default_from_dump({'mod::params::test' => :undef}) }.default).must_be_nil }
      specify { _(with_value.tap { |p| p.set_default_from_dump({'42' => 'fail'}) }.default).must_equal '42' }
      specify { _(param.tap { |p| p.set_default_from_dump({'test' => '42'}) }.default).must_equal '42' }
    end

    describe '#unset_value' do
      let(:unset) { param.tap { |p| p.unset_value } }
      specify do
        param.manifest_default = 'def'
        param.value = 'val'
        _(unset.value).must_equal 'def'
      end
    end

    describe '#value=' do
      specify { _(param.tap { |p| p.value = 'foo' }.value).must_equal 'foo' }
      specify { _(param.tap { |p| p.value = 'foo' }.value_set).must_equal true }
      specify { _(param.tap { |p| p.value = 'UNDEF' }.value).must_be_nil }
      specify { _(param.tap { |p| p.value = 'UNDEF' }.value_set).must_equal true }
      specify { _(param.tap { |p| p.value = ::HighLine::String('foo') }.value).must_equal 'foo' }
      specify { _(param.tap { |p| p.value = ::HighLine::String('foo') }.value.class).must_equal ::String }
      specify { _(param.tap { |p| p.value = [::HighLine::String('foo')] }.value).must_equal ['foo'] }
      specify { _(param.tap { |p| p.value = [::HighLine::String('foo')] }.value.first.class).must_equal ::String }
      specify { _(param.tap { |p| p.value = {::HighLine::String('foo') => ::HighLine::String('bar')} }.value).must_equal({'foo' => 'bar'}) }
      specify { _(param.tap { |p| p.value = {::HighLine::String('foo') => ::HighLine::String('bar')} }.value.keys.first.class).must_equal ::String }
      specify { _(param.tap { |p| p.value = {::HighLine::String('foo') => ::HighLine::String('bar')} }.value.values.first.class).must_equal ::String }
    end
  end
end
