require 'test_helper'

module Kafo
  module DataTypes
    describe Optional do
      describe "registered" do
        it { _(DataType.new_from_string('Optional[String]')).must_be_instance_of Optional }
        it { _(DataType.new_from_string('Optional[String]').inner_type).must_be_instance_of String }
      end

      describe "#to_s" do
        it { _(Optional.new('test').to_s).must_equal '"test" or undef' }
        it { _(Optional.new('String').to_s).must_equal 'string or undef' }
      end

      describe "#valid?" do
        it { _(Optional.new('test').valid?(nil)).must_equal true }
        it { _(Optional.new('test').valid?('test')).must_equal true }
        it { _(Optional.new('test').valid?('foo')).must_equal false }
        it { _(Optional.new('String').valid?(nil)).must_equal true }
        it { _(Optional.new('String').valid?('foo')).must_equal true }
        it { _(Optional.new('String').valid?(1)).must_equal false }
      end
    end
  end
end
