require 'test_helper'

module Kafo
  module DataTypes
    describe Scalar do
      describe "registered" do
        it { DataType.new_from_string('Scalar').must_be_instance_of Scalar }
      end

      describe "#typecast" do
        it { Scalar.new.typecast(42).must_equal 42 }
        it { Scalar.new.typecast('42').must_equal 42 }
        it { Scalar.new.typecast('foo').must_equal 'foo' }
      end

      describe "#valid?" do
        it { Scalar.new.valid?([]).must_equal false }
        it { Scalar.new.valid?('test').must_equal true }
        it { Scalar.new.valid?(1).must_equal true }
      end
    end
  end
end
