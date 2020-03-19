require 'test_helper'

module Kafo
  module DataTypes
    describe TypeReference do
      describe "registered" do
        it { _(DataType.new_from_string('TypeReference[String]')).must_be_instance_of TypeReference }
      end

      describe "#to_s" do
        it { _(TypeReference.new('String').to_s).must_equal 'string' }
      end

      describe "#valid?" do
        it { _(TypeReference.new('String').valid?('foo')).must_equal true }
        it { _(TypeReference.new('String').valid?(1)).must_equal false }
      end
    end
  end
end
