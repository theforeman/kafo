require 'test_helper'

module Kafo
  describe Param do
    let(:param) { Param.new(nil, 'test') }

    describe "#visible?" do
      describe "without condition" do
        specify { param.must_be :visible? }
      end

      describe "with true condition" do
        before { param.condition = 'true' }
        specify { param.must_be :visible? }
      end

      describe "with false condition" do
        before { param.condition = 'false' }
        specify { param.wont_be :visible? }
      end

      describe "with context" do
        let(:context) { [Param.new(nil, 'context').tap { |p| p.value = true }] }
        before { param.condition = '$context' }
        specify { param.visible?(context).must_equal true }
      end
    end

    describe "#condition_value" do
      before { param.value = 'tester' }
      specify { param.condition_value.must_be_kind_of String }
    end

    describe "group" do
      it "should return empty array by default" do
        param.groups.must_equal []
      end

      describe "when nil was set" do
        before { param.groups = nil }
        specify { param.groups.must_equal [] }
      end

      describe "groups were set" do
        before { param.groups = [ ParamGroup.new('one'), ParamGroup.new('two') ] }
        let(:group_names) { param.groups.map(&:name) }
        specify { group_names.must_include 'one' }
        specify { group_names.must_include 'two' }
      end
    end

  end
end
