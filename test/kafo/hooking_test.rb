require 'test_helper'

module Kafo
  describe Hooking do
    let(:hooking) { Hooking.new }

    describe "#register_pre" do
      before { hooking.register_pre(:no1) { 'got executed' } }

      let(:pre_hooks) { hooking.hooks[:pre] }
      specify { _(pre_hooks.keys).must_include(:no1) }

      let(:pre_hook_no1) { pre_hooks[:no1] }
      specify { _(pre_hook_no1.call).must_equal 'got executed' }
    end

    describe "#execute" do
      before do
        hooking.register_pre(:no1) { puts 's1' }
        hooking.register_pre('str1') { puts 'r1' }
        hooking.register_pre(:no2) { puts 's2' }
        hooking.register_pre('str2') { puts 'r2' }
      end

      describe "#execute(:pre)" do
        before do
          @out, @err = capture_io do
            hooking.execute(:pre)
          end
        end

        specify { _(@out).must_include 's2' }
        specify { _(@out).must_include 's1' }
        specify { _(@out).must_include 'r1' }
        specify { _(@out).must_include 'r2' }
        specify { _(@out).must_match(/.*s1.*s2.*r1.*r2.*/m) }
      end

      describe "#execute(:post)" do
        before do
          @out, @err = capture_io do
            hooking.execute(:post)
          end
        end

        specify { _(@out).must_be_empty }
      end
    end
  end
end
