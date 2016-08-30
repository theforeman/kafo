require 'test_helper'

module Kafo
  describe HookContext do
    let(:context) { HookContext.new(Object.new) }

    describe "api" do
      specify { context.respond_to?(:logger).must_equal true }
      specify { context.respond_to?(:app_option).must_equal true }
      specify { context.respond_to?(:app_value).must_equal true }
      specify { context.respond_to?(:param).must_equal true }
      specify { context.respond_to?(:add_module).must_equal true }
      specify { context.respond_to?(:module_enabled?).must_equal true }
    end
  end
end
