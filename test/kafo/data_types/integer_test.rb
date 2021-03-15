require 'test_helper'

module Kafo
  module DataTypes
    describe Integer do
      describe "registered" do
        it { _(DataType.new_from_string('Integer')).must_be_instance_of Integer }
      end

      describe "#to_s" do
        it { _(Integer.new.to_s).must_equal 'integer' }
        it { _(Integer.new(2).to_s).must_equal 'integer (at least 2)' }
        it { _(Integer.new(:default, 2).to_s).must_equal 'integer (up to 2)' }
        it { _(Integer.new(1, 2).to_s).must_equal 'integer (between 1 and 2)' }
      end

      describe "#typecast" do
        it { _(Integer.new.typecast(1)).must_equal 1 }
        it { _(Integer.new.typecast('1')).must_equal 1 }
        it { _(Integer.new.typecast('1.5')).must_equal '1.5' }
        it { _(Integer.new.typecast(' 10 ')).must_equal 10 }
        it { _(Integer.new.typecast('1foo')).must_equal '1foo' }
        it { _(Integer.new.typecast('foo')).must_equal 'foo' }
      end

      describe "#valid?" do
        it { _(Integer.new.valid?(-1)).must_equal true }
        it { _(Integer.new.valid?(1)).must_equal true }
        it { _(Integer.new.valid?('foo')).must_equal false }
        it { _(Integer.new(1).valid?(1)).must_equal true }
        it { _(Integer.new(2).valid?(1)).must_equal false }
        it { _(Integer.new(1, 2).valid?(1)).must_equal true }
        it { _(Integer.new(1, 2).valid?(3)).must_equal false }
      end
    end
  end
end
