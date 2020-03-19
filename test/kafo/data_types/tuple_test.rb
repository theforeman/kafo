require 'test_helper'

module Kafo
  module DataTypes
    describe Tuple do
      describe "registered" do
        it { _(DataType.new_from_string('Tuple')).must_be_instance_of Tuple }
      end

      describe "#condition_value" do
        it { _(Tuple.new('String').condition_value([])).must_equal '[  ]' }
        it { _(Tuple.new('String').condition_value(['foo'])).must_equal '[ "foo" ]' }
        it { _(Tuple.new('String').condition_value(['foo', 'bar'])).must_equal '[ "foo", "bar" ]' }
      end

      describe "#multivalued?" do
        it { _(Tuple.new('String').multivalued?).must_equal true }
      end

      describe "#to_s" do
        it { _(Tuple.new('Integer').to_s).must_equal 'tuple of integer' }
        it { _(Tuple.new('Integer', 'Any').to_s).must_equal 'tuple of integer, any' }
        it { _(Tuple.new('Integer', 2, :default).to_s).must_equal 'tuple of integer (at least 2 items)' }
        it { _(Tuple.new('Integer', 0, 2).to_s).must_equal 'tuple of integer (up to 2 items)' }
        it { _(Tuple.new('Integer', 1, 2).to_s).must_equal 'tuple of integer (between 1 and 2 items)' }
      end

      describe "#typecast" do
        it { _(Tuple.new('Integer').typecast(['EMPTY_ARRAY'])).must_equal [] }
        it { _(Tuple.new('Integer').typecast(['1'])).must_equal [1] }
        it { _(Tuple.new('Integer', 'Integer').typecast(['1', '2'])).must_equal [1, 2] }
        it { _(Tuple.new('Integer').typecast(['1', '2'])).must_equal [1, 2] }
      end

      describe "#valid?" do
        it { _(Tuple.new('Integer').valid?(1)).must_equal false }
        it { _(Tuple.new('Integer').valid?([1])).must_equal true }
        it { _(Tuple.new('Integer').valid?([1, 'test'])).must_equal false }
        it { _(Tuple.new('Integer', 'Integer').valid?([1, 'test'])).must_equal false }
        it { _(Tuple.new('Data', 2, :default).valid?(['foo'])).must_equal false }
        it { _(Tuple.new('Data', 2, :default).valid?(['foo', 'bar'])).must_equal true }
        it { _(Tuple.new('Data', 1, 2).valid?(['foo', 'bar'])).must_equal true }
        it { _(Tuple.new('Data', 1, 2).valid?(['foo', 'bar', 'baz'])).must_equal false }
      end
    end
  end
end
