require 'test_helper'

module Kafo
  module DataTypes
    describe Undef do
      describe "registered" do
        it { _(DataType.new_from_string('Undef')).must_be_instance_of Undef }
      end

      describe "#valid?" do
        it { _(Undef.new.valid?(nil)).must_equal true }
        it { _(Undef.new.valid?('test')).must_equal false }
      end
    end
  end
end
