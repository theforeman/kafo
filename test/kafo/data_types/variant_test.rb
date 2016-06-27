require 'test_helper'

module Kafo
  module DataTypes
    describe Variant do
      describe "registered" do
        it { DataType.new_from_string('Variant[String]').must_be_instance_of Variant }
      end

      describe "#condition_value" do
        it { Variant.new('String', 'Integer').condition_value(1).must_equal '1' }
      end

      describe "#dump_default" do
        it { Variant.new('String', 'Integer').dump_default(1).must_equal '"1"' }
      end

      describe "#multivalued?" do
        it { Variant.new('String', 'Integer').multivalued?.must_equal false }
        it { Variant.new('String', 'Array').multivalued?.must_equal true }
      end

      describe "#typecast" do
        it { Variant.new('Integer', 'Boolean').typecast('42').must_equal 42 }
        it { Variant.new('Integer', 'Boolean').typecast('true').must_equal true }
        it { Variant.new('Integer', 'Boolean').typecast('foo').must_equal 'foo' }
      end

      describe "#valid?" do
        it { Variant.new('String', 'Integer').valid?([]).must_equal false }
        it { Variant.new('String', 'Integer').valid?('1').must_equal true }
        it { Variant.new('String', 'Integer').valid?(1).must_equal true }
      end
    end
  end
end
