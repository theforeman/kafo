require 'test_helper'

module Kafo
  module DataTypes
    describe Enum do
      describe "registered" do
        it { _(DataType.new_from_string('Enum')).must_be_instance_of Enum }
      end

      describe "#to_s" do
        it { _(Enum.new('foo').to_s).must_equal '"foo"' }
        it { _(Enum.new('foo', 'bar').to_s).must_equal '"foo" or "bar"' }
      end

      describe "#valid?" do
        it { _(Enum.new('foo').valid?(1)).must_equal false }
        it { _(Enum.new('foo').valid?('foo')).must_equal true }
        it { _(Enum.new('foo').valid?('bar')).must_equal false }
        it { _(Enum.new('foo', 'bar').valid?('bar')).must_equal true }
      end
    end
  end
end
