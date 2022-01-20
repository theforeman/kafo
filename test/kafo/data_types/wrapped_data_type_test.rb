require 'test_helper'

module Kafo
  module DataTypes
    describe WrappedDataType do
      describe "registered Sensitive" do
        it { _(DataType.new_from_string('Sensitive[String]')).must_be_instance_of WrappedDataType }
      end

      describe "registered Variant" do
        it { _(DataType.new_from_string('Variant[String]')).must_be_instance_of WrappedDataType }
      end

      describe "#condition_value" do
        it { _(WrappedDataType.new('String', 'Integer').condition_value(1)).must_equal '1' }
      end

      describe "#dump_default" do
        it { _(WrappedDataType.new('String', 'Integer').dump_default(1)).must_equal '"1"' }
      end

      describe "#multivalued?" do
        it { _(WrappedDataType.new('String', 'Integer').multivalued?).must_equal false }
        it { _(WrappedDataType.new('String', 'Array').multivalued?).must_equal true }
      end

      describe "#typecast" do
        it { _(WrappedDataType.new('Integer', 'Boolean').typecast('42')).must_equal 42 }
        it { _(WrappedDataType.new('Integer', 'Boolean').typecast('true')).must_equal true }
        it { _(WrappedDataType.new('Integer', 'Boolean').typecast('foo')).must_equal 'foo' }
      end

      describe "#valid?" do
        it { _(WrappedDataType.new('String', 'Integer').valid?([])).must_equal false }
        it { _(WrappedDataType.new('String', 'Integer').valid?('1')).must_equal true }
        it { _(WrappedDataType.new('String', 'Integer').valid?(1)).must_equal true }
      end
    end
  end
end
