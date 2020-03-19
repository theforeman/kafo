require 'test_helper'

module Kafo
  module DataTypes
    describe Struct do
      describe "registered" do
        it { _(DataType.new_from_string('Struct[{}]')).must_be_instance_of Struct }
      end

      describe "#condition_value" do
        it { _(Struct.new({}).condition_value({})).must_equal '{}' }
        it { _(Struct.new({'foo' => 'String'}).condition_value({'foo' => 'bar'})).must_equal '{"foo"=>"bar"}' }
      end

      describe "#multivalued?" do
        it { _(Struct.new({}).multivalued?).must_equal true }
      end

      describe "#to_s" do
        it { _(Struct.new('foo' => 'Integer').to_s).must_equal 'struct containing "foo" (integer)' }
        it { _(Struct.new('foo' => 'Integer', 'Optional["bar"]' => 'Integer').to_s).must_equal 'struct containing "bar" (optional integer), "foo" (integer)' }
        it { _(Struct.new('foo' => 'Integer', 'NotUndef["bar"]' => 'Integer').to_s).must_equal 'struct containing "bar" (required integer), "foo" (integer)' }
      end

      describe "#typecast" do
        it { _(Struct.new('foo' => 'Integer').typecast('foo' => 1)).must_equal('foo' => 1) }
        it { _(Struct.new('foo' => 'Integer').typecast(['foo:1'])).must_equal('foo' => 1) }
        it { _(Struct.new('Optional["foo"]' => 'Integer').typecast(['foo:1'])).must_equal('foo' => 1) }
        it { _(Struct.new('foo' => 'Integer').typecast(['unknown:1'])).must_equal('unknown' => '1') }
        it { _(Struct.new('foo' => 'Integer').typecast(['EMPTY_HASH'])).must_equal({}) }
      end

      describe "#valid?" do
        it { _(Struct.new({}).valid?(nil)).must_equal false }
        it { _(Struct.new({}).valid?({})).must_equal true }
        it { _(Struct.new({}).valid?('foo' => 1)).must_equal false }
        it { _(Struct.new('foo' => 'Integer').valid?('foo' => 1)).must_equal true }
        it { _(Struct.new('foo' => 'Integer').valid?('foo' => nil)).must_equal false }
        it { _(Struct.new('foo' => 'Integer', 'Optional["bar"]' => 'Integer').valid?('foo' => 1)).must_equal true }
        it { _(Struct.new('foo' => 'Integer', 'Optional["bar"]' => 'Integer').valid?('foo' => 1, 'bar' => 1)).must_equal true }
        it { _(Struct.new('foo' => 'Integer', 'NotUndef["bar"]' => 'Integer').valid?('foo' => 1)).must_equal false }
        it { _(Struct.new('foo' => 'Integer', 'NotUndef["bar"]' => 'Integer').valid?('foo' => 1, 'bar' => 1)).must_equal true }
      end
    end
  end
end
