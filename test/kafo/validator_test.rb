require 'test_helper'

DummyParam = Struct.new(:name, :value)

module Kafo
  describe Validator do
    let(:validator) { Validator.new }

    describe "#errors" do
      specify { validator.tap { |v| v.validate_string([1]) }.errors.must_equal ["1 is not a valid string"] }
    end

    describe "#validate_absolute_path" do
      specify { validator.validate_absolute_path(['/opt']).must_equal true }
      specify { validator.validate_absolute_path(['/opt', '/usr']).must_equal true }
      specify { validator.validate_absolute_path(['./opt']).must_equal false }
    end

    describe "#validate_array" do
      specify { validator.validate_array([['a','b','c']]).must_equal true }
      specify { validator.validate_array(['a']).must_equal false }
      specify { validator.validate_array([nil]).must_equal false }
    end

    describe "#validate_bool" do
      specify { validator.validate_bool([true]).must_equal true }
      specify { validator.validate_bool([false]).must_equal true }
      specify { validator.validate_bool(['false']).must_equal false }
      specify { validator.validate_bool([0]).must_equal false }
      specify { validator.validate_bool([nil]).must_equal false }
    end

    describe "#validate_hash" do
      specify { validator.validate_hash([{'a' => 'b'}]).must_equal true }
      specify { validator.validate_hash(['a']).must_equal false }
      specify { validator.validate_hash([nil]).must_equal false }
    end

    describe "#validate_integer" do
      specify { validator.validate_integer([1]).must_equal true }
      specify { validator.validate_integer(['1']).must_equal true }
      specify { validator.validate_integer(['foo']).must_equal false }
      specify { validator.validate_integer([nil]).must_equal false }

      # maximums
      specify { validator.validate_integer([1, 2]).must_equal true }
      specify { validator.validate_integer([3, 2]).must_equal false }

      # minimums
      specify { validator.validate_integer([3, nil, 2]).must_equal true }
      specify { validator.validate_integer([1, nil, 2]).must_equal false }

      # min and max
      specify { validator.validate_integer([3, 5, 2]).must_equal true }
      specify { validator.validate_integer([1, 5, 2]).must_equal false }
      specify { validator.validate_integer(['3', '5', '2']).must_equal true }
    end

    describe "#validate_listen_on" do
      specify { validator.validate_listen_on(['http']).must_equal true }
      specify { validator.validate_listen_on(['https']).must_equal true }
      specify { validator.validate_listen_on(['both']).must_equal true }
      specify { validator.validate_listen_on(['foo']).must_equal false }
      specify { validator.validate_listen_on([1]).must_equal false }
      specify { validator.validate_listen_on(['http', 'https']).must_equal true }
      specify { validator.validate_listen_on([nil]).must_equal false }
    end

    describe "#validate_re" do
      specify { validator.validate_re(['www.theformean.org', '^.*\.org$']).must_equal true }
      specify { validator.validate_re(['www.theformean,org', '^.*\.org$']).must_equal false }
      specify { validator.validate_re(["ipmitool", "^(freeipmi|ipmitool|shell)$"]).must_equal true }
      specify { validator.validate_re(["xipmi", "^(freeipmi|ipmitool|shell)$"]).must_equal false }
      specify { validator.validate_re([nil, "^(freeipmi|ipmitool|shell)$"]).must_equal false }
      specify { validator.validate_re(["ipmitool", ["^freeipmi$", "^ipmitool$"]]).must_equal true }
      specify { validator.validate_re(["xipmi", ["^freeipmi$", "^ipmitool$"]]).must_equal false }

      describe "with error message" do
        specify { validator.validate_re(["foo", "^bar$", "Does not match"]).must_equal false }
        specify { validator.validate_re(["bar", "^bar$", "Does not match"]).must_equal true }
      end
    end

    describe "#validate_string" do
      specify { validator.validate_string([1]).must_equal false }
      specify { validator.validate_string(['foo']).must_equal true }
      specify { validator.validate_string([1, 'foo']).must_equal false }
      specify { validator.validate_string(['foo', 'bar']).must_equal true }
      specify { validator.validate_string([nil]).must_equal false }
    end

    describe "#method_missing responds to unknown validation functions" do
      specify { validator.validate_unknown_function(['foo']).must_equal true }
      specify { Proc.new { validator.unknown_method(['foo']) }.must_raise NoMethodError }
    end
  end
end
