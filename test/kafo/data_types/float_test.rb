require 'test_helper'

module Kafo
  module DataTypes
    describe Float do
      describe "registered" do
        it { _(DataType.new_from_string('Float')).must_be_instance_of Float }
      end

      describe "#to_s" do
        it { _(Float.new.to_s).must_equal 'float' }
        it { _(Float.new(2).to_s).must_equal 'float (at least 2)' }
        it { _(Float.new(:default, 2).to_s).must_equal 'float (up to 2)' }
        it { _(Float.new(1, 2).to_s).must_equal 'float (between 1 and 2)' }
      end

      describe "#typecast" do
        it { _(Float.new.typecast(1.5)).must_be_close_to 1.5 }
        it { _(Float.new.typecast('1.5')).must_be_close_to 1.5 }
        it { _(Float.new.typecast('1foo')).must_be_close_to 1.0 }
        it { _(Float.new.typecast('foo')).must_equal 'foo' }
      end

      describe "#valid?" do
        it { _(Float.new.valid?(-1.5)).must_equal true }
        it { _(Float.new.valid?(1.5)).must_equal true }
        it { _(Float.new.valid?('foo')).must_equal false }
        it { _(Float.new(1).valid?(1.5)).must_equal true }
        it { _(Float.new(2).valid?(1.5)).must_equal false }
        it { _(Float.new(1, 2).valid?(1.5)).must_equal true }
        it { _(Float.new(1, 1.2).valid?(1.5)).must_equal false }
      end
    end
  end
end
