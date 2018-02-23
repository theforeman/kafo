require 'test_helper'

module Kafo
  describe Condition do
    describe "evaluation of condition without substitution" do
      describe "simple true" do
        let(:condition) { Condition.new('true') }
        specify { condition.evaluate.must_equal true }
      end

      describe "simple false" do
        let(:condition) { Condition.new('false') }
        specify { condition.evaluate.must_equal false }
      end

      describe "complex ruby expression" do
        let(:condition) { Condition.new('(false || (true && false) || true)') }
        specify { condition.evaluate.must_equal true }
      end

      describe "result is always converted to boolean - e.g. nil" do
        let(:condition) { Condition.new('nil') }
        specify { condition.evaluate.must_equal false }
      end

      describe "result is always converted to boolean - e.g. string" do
        let(:condition) { Condition.new('"something"') }
        specify { condition.evaluate.must_equal true }
      end
    end

    describe "evaluation of condition with substitution" do
      let(:builder) { Kafo::PuppetModule.new('mymod') }
      let(:str) { Param.new(builder, 'str', 'String').tap { |p| p.value = 'tester' } }
      let(:arr) { Param.new(builder, 'arr', 'Array[String]').tap { |p| p.value = ['root', 'toor'] } }
      let(:int) { Param.new(builder, 'int', 'Integer').tap { |p| p.value = 3 } }
      let(:bool) { Param.new(builder, 'bool', 'Boolean').tap { |p| p.value = false } }
      let(:context) { [str, arr, int, bool, pass] }

      describe "substitutes all variables for param values" do
        let(:condition) { Condition.new('$str == "tester" && $arr.include?("toor") && $int > 2 && !$bool', context) }
        specify { condition.evaluate.must_equal true }
      end

      describe "raise error if some variable is missing in context" do
        let(:condition) { Condition.new('$str == "tester"', []) }
        specify { Proc.new { condition.evaluate }.must_raise ConditionError }
      end
    end
  end
end
