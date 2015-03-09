require 'test_helper'

module Kafo
  describe Params::Hash do

    let :dummy_module do
      PuppetModule.new('dummy', nil)
    end

    describe "non-empty hash" do

      subject do
        Params::Hash.new(dummy_module, "hash").tap do |param|
          param.value = { 'a' => 'b' }
        end
      end

      it 'is saves it untouched' do
        subject.value.must_equal({ 'a' => 'b' })
      end

    end

    describe "empty hash specified by keyword EMPTY_HASH" do

      subject do
        Params::Hash.new(dummy_module, "hash").tap do |param|
          param.value = ['EMPTY_HASH']
        end
      end

      it 'is converts value to empty hash' do
        subject.value.must_equal({})
      end

    end

  end
end
