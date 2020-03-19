require 'test_helper'

module Kafo
  module DataTypes
    describe Array do
      describe "registered" do
        it { _(DataType.new_from_string('Array')).must_be_instance_of Array }
      end

      describe "#condition_value" do
        it { _(Array.new.condition_value([])).must_equal '[  ]' }
        it { _(Array.new.condition_value(['foo'])).must_equal '[ "foo" ]' }
        it { _(Array.new.condition_value(['foo', 'bar'])).must_equal '[ "foo", "bar" ]' }
      end

      describe "#multivalued?" do
        it { _(Array.new.multivalued?).must_equal true }
      end

      describe "#to_s" do
        it { _(Array.new.to_s).must_equal 'array of any' }
        it { _(Array.new('Integer').to_s).must_equal 'array of integer' }
        it { _(Array.new('Integer', 2).to_s).must_equal 'array of integer (at least 2 items)' }
        it { _(Array.new('Integer', 0, 2).to_s).must_equal 'array of integer (up to 2 items)' }
        it { _(Array.new('Integer', 1, 2).to_s).must_equal 'array of integer (between 1 and 2 items)' }
      end

      describe "#typecast" do
        it { _(Array.new.typecast(nil)).must_be_nil }
        it { _(Array.new.typecast(['EMPTY_ARRAY'])).must_equal [] }
        it { _(Array.new.typecast(['foo'])).must_equal ['foo'] }
        it { _(Array.new.typecast([['foo']])).must_equal ['foo'] }
        it { _(Array.new('Integer').typecast(['1'])).must_equal [1] }
      end

      describe "#valid?" do
        it { _(Array.new.valid?(nil)).must_equal false }
        it { _(Array.new.valid?([])).must_equal true }
        it { _(Array.new.valid?([1])).must_equal true }
        it { _(Array.new('Integer[2]').valid?([1])).must_equal false }
        it { _(Array.new('Integer[2]').valid?([2])).must_equal true }
        it { _(Array.new('Data', 2).valid?(['foo'])).must_equal false }
        it { _(Array.new('Data', 2).valid?(['foo', 'bar'])).must_equal true }
        it { _(Array.new('Data', 1, 2).valid?(['foo', 'bar'])).must_equal true }
        it { _(Array.new('Data', 1, 2).valid?(['foo', 'bar', 'baz'])).must_equal false }
      end
    end
  end
end
