require 'test_helper'

module Kafo
  module DataTypes
    describe Any do
      describe "registered" do
        it { DataType.new_from_string('Any').must_be_instance_of Any }
      end
    end
  end
end
