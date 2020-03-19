require 'test_helper'

module Kafo
  module DataTypes
    describe Boolean do
      describe "registered" do
        it { _(DataType.new_from_string('Boolean')).must_be_instance_of Boolean }
      end

      describe "#typecast" do
        ['0', 'false', 'f', 'n', false].each do |value|
          it { _(Boolean.new.typecast(value)).must_equal false }
        end
        ['1', 'true', 't', 'y', true].each do |value|
          it { _(Boolean.new.typecast(value)).must_equal true }
        end
        it { _(Boolean.new.typecast('foo')).must_equal 'foo' }
      end

      describe "#valid?" do
        it { _(Boolean.new.valid?(true)).must_equal true }
        it { _(Boolean.new.valid?(false)).must_equal true }
        it { _(Boolean.new.valid?('foo')).must_equal false }
      end
    end
  end
end
