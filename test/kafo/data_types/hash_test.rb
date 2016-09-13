require 'test_helper'

module Kafo
  module DataTypes
    describe Hash do
      describe "registered" do
        it { DataType.new_from_string('Hash').must_be_instance_of Hash }
      end

      describe "#condition_value" do
        it { Hash.new.condition_value({}).must_equal '{}' }
        it { Hash.new.condition_value({'foo' => 'bar'}).must_equal '{"foo"=>"bar"}' }
      end

      describe "#multivalued?" do
        it { Hash.new.multivalued?.must_equal true }
      end

      describe "#to_s" do
        it { Hash.new.to_s.must_equal 'hash of scalar/any' }
        it { Hash.new('Integer', 'String').to_s.must_equal 'hash of integer/string' }
        it { Hash.new('Integer', 'String', 2).to_s.must_equal 'hash of integer/string (at least 2 items)' }
        it { Hash.new('Integer', 'String', 0, 2).to_s.must_equal 'hash of integer/string (up to 2 items)' }
        it { Hash.new('Integer', 'String', 1, 2).to_s.must_equal 'hash of integer/string (between 1 and 2 items)' }
      end

      describe "#typecast" do
        it { Hash.new.typecast(nil).must_be_nil }
        it { Hash.new.typecast({'foo' => 'bar'}).must_equal({'foo' => 'bar'}) }
        it { Hash.new.typecast(['EMPTY_HASH']).must_equal({}) }
        it { Hash.new.typecast(['foo:bar']).must_equal({'foo' => 'bar'}) }
        it { Hash.new('Integer', 'Integer').typecast(['1:1']).must_equal({1 => 1}) }
      end

      describe "#valid?" do
        it { Hash.new.valid?(nil).must_equal false }
        it { Hash.new.valid?({}).must_equal true }
        it { Hash.new.valid?({1 => 1}).must_equal true }
        it { Hash.new('Integer[2]', 'Integer[1]').valid?({1 => 1}).must_equal false }
        it { Hash.new('Integer[1]', 'Integer[2]').valid?({1 => 1}).must_equal false }
        it { Hash.new('Scalar', 'Data', 2).valid?({'foo' => 'foo'}).must_equal false }
        it { Hash.new('Scalar', 'Data', 2).valid?({'foo' => 'foo', 'bar' => 'bar'}).must_equal true }
        it { Hash.new('Scalar', 'Data', 1, 2).valid?({'foo' => 'foo', 'bar' => 'bar'}).must_equal true }
        it { Hash.new('Scalar', 'Data', 1, 2).valid?({'foo' => 'foo', 'bar' => 'bar', 'baz' => 'baz'}).must_equal false }
      end
    end
  end
end
