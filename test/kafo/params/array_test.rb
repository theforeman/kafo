require 'test_helper'

module Kafo
  describe Params::Array do

    let :dummy_module do
      PuppetModule.new('dummy', nil)
    end

    describe "non-empty array" do

      subject do
        Params::Array.new(dummy_module, "array").tap do |param|
          param.value = ['a', 'b']
        end
      end

      it 'is saves it untouched' do
        subject.value.must_equal ['a', 'b']
      end

    end

    describe "empty array specified by keyword EMPTY_ARRAY" do

      subject do
        Params::Array.new(dummy_module, "array").tap do |param|
          param.value = ['EMPTY_ARRAY']
        end
      end

      it 'is converts value to empty array' do
        subject.value.must_equal []
      end

    end

  end
end
