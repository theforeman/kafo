require 'test_helper'

module Kafo
  module DataTypes
    describe Numeric do
      describe "registered" do
        it { _(DataType.new_from_string('Numeric')).must_be_instance_of Numeric }
      end

      describe "#typecast" do
        it { _(Numeric.new.typecast(1.1)).must_be_close_to 1.1 }
        it { _(Numeric.new.typecast('1.1')).must_be_close_to 1.1 }
        it { _(Numeric.new.typecast('1foo')).must_be_close_to 1.0 }
        it { _(Numeric.new.typecast('foo')).must_equal 'foo' }
      end

      describe "#valid?" do
        it { _(Numeric.new.valid?(1)).must_equal true }
        it { _(Numeric.new.valid?(1.1)).must_equal true }
        it { _(Numeric.new.valid?('foo')).must_equal false }
      end
    end
  end
end
