require 'test_helper'

DummyParam = Struct.new(:name, :value)

module Kafo
  describe Validator do
    let(:params) do
      [
          DummyParam.new('some_bool', true),
          DummyParam.new('some_string', 'www.theforeman.org'),
          DummyParam.new('some_integer', 1),
          DummyParam.new('some_array', [1])
      ]
    end

    let(:validator) { Validator.new(params) }

    describe "#lookupvar(name)" do
      specify { validator.lookupvar('some_bool').must_equal true }
      specify { validator.lookupvar('some_string').must_equal 'www.theforeman.org' }
      specify { validator.lookupvar('some_integer').must_equal 1 }
      specify { validator.lookupvar('some_array').must_equal [1] }
      specify { validator.lookupvar('some_nonsense').must_equal nil }
    end

    describe "#[name]" do
      it "should reuse #lookupvar" do
        validator.stub :lookupvar, 'value' do
          validator['some_bool'].must_equal 'value'
        end
      end
    end

    describe "validations using method missing" do
      it "should validate boolean" do
        validator.function_validate_bool([true]).wont_equal false
        validator.function_validate_bool([false]).wont_equal false
        validator.function_validate_bool(['false']).must_equal false
        validator.function_validate_bool([0]).must_equal false
      end

      it "should validate regular expression" do
        validator.function_validate_re(['www.theformean.org', '^.*\.org$']).wont_equal false
        validator.function_validate_re(['www.theformean,org', '^.*\.org$']).must_equal false
        validator.function_validate_re(["ipmitool", "^(freeipmi|ipmitool|shell)$"]).wont_equal false
        validator.function_validate_re(["xipmi", "^(freeipmi|ipmitool|shell)$"]).must_equal false
      end

      it "should validate array" do
        validator.function_validate_array([['a','b','c']]).wont_equal false
        validator.function_validate_array(['a']).must_equal false
      end
    end


  end
end
