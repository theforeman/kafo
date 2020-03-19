require 'test_helper'

module Kafo
  module DataTypes
    describe Scalar do
      describe "registered" do
        it { _(DataType.new_from_string('Scalar')).must_be_instance_of Scalar }
      end

      describe "#typecast" do
        it { _(Scalar.new.typecast(42)).must_equal 42 }
        it { _(Scalar.new.typecast('42')).must_equal 42 }
        it { _(Scalar.new.typecast('foo')).must_equal 'foo' }
      end

      describe "#valid?" do
        it { _(Scalar.new.valid?([])).must_equal false }
        it { _(Scalar.new.valid?('test')).must_equal true }
        it { _(Scalar.new.valid?(1)).must_equal true }
      end
    end
  end
end
