require 'test_helper'

module Kafo
  module DataTypes
    describe Regexp do
      describe "registered" do
        it { DataType.new_from_string('Regexp').must_be_instance_of Regexp }
      end

      describe "#valid?" do
        it { Regexp.new.valid?([]).must_equal false }
        it { Regexp.new.valid?('.*').must_equal true }
      end
    end
  end
end
