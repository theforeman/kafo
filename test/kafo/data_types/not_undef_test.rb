require 'test_helper'

module Kafo
  module DataTypes
    describe NotUndef do
      describe "registered" do
        it { DataType.new_from_string('NotUndef[String]').must_be_instance_of NotUndef }
        it { DataType.new_from_string('NotUndef[String]').inner_type.must_be_instance_of String }
      end

      describe "#to_s" do
        it { NotUndef.new('test').to_s.must_equal '"test" but not undef' }
        it { NotUndef.new('String').to_s.must_equal 'string but not undef' }
      end

      describe "#valid?" do
        it { NotUndef.new('test').valid?(nil).must_equal false }
        it { NotUndef.new('test').valid?('test').must_equal true }
        it { NotUndef.new('test').valid?('foo').must_equal false }
        it { NotUndef.new('String').valid?(nil).must_equal false }
        it { NotUndef.new('String').valid?('foo').must_equal true }
        it { NotUndef.new('String').valid?(1).must_equal false }
      end
    end
  end
end
