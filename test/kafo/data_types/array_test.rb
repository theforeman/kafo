require 'test_helper'

module Kafo
  module DataTypes
    describe Array do
      describe "registered" do
        it { DataType.new_from_string('Array').must_be_instance_of Array }
      end

      describe "#condition_value" do
        it { Array.new.condition_value([]).must_equal '[  ]' }
        it { Array.new.condition_value(['foo']).must_equal '[ "foo" ]' }
        it { Array.new.condition_value(['foo', 'bar']).must_equal '[ "foo", "bar" ]' }
      end

      describe "#multivalued?" do
        it { Array.new.multivalued?.must_equal true }
      end

      describe "#to_s" do
        it { Array.new.to_s.must_equal 'array of any' }
        it { Array.new('Integer').to_s.must_equal 'array of integer' }
        it { Array.new('Integer', 2).to_s.must_equal 'array of integer (at least 2 items)' }
        it { Array.new('Integer', 0, 2).to_s.must_equal 'array of integer (up to 2 items)' }
        it { Array.new('Integer', 1, 2).to_s.must_equal 'array of integer (between 1 and 2 items)' }
      end

      describe "#typecast" do
        it { Array.new.typecast(nil).must_be_nil }
        it { Array.new.typecast(['EMPTY_ARRAY']).must_equal [] }
        it { Array.new.typecast(['foo']).must_equal ['foo'] }
        it { Array.new.typecast([['foo']]).must_equal ['foo'] }
        it { Array.new('Integer').typecast(['1']).must_equal [1] }
      end

      describe "#valid?" do
        it { Array.new.valid?(nil).must_equal false }
        it { Array.new.valid?([]).must_equal true }
        it { Array.new.valid?([1]).must_equal true }
        it { Array.new('Integer[2]').valid?([1]).must_equal false }
        it { Array.new('Integer[2]').valid?([2]).must_equal true }
        it { Array.new('Data', 2).valid?(['foo']).must_equal false }
        it { Array.new('Data', 2).valid?(['foo', 'bar']).must_equal true }
        it { Array.new('Data', 1, 2).valid?(['foo', 'bar']).must_equal true }
        it { Array.new('Data', 1, 2).valid?(['foo', 'bar', 'baz']).must_equal false }
      end
    end
  end
end
