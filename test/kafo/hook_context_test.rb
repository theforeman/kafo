require 'test_helper'

module Kafo
  describe HookContext do
    let(:context) { HookContext.new(Object.new) }

    describe "api" do
      specify { context.respond_to?(:logger) }
      specify { context.respond_to?(:app_option) }
      specify { context.respond_to?(:app_value) }
      specify { context.respond_to?(:param) }
    end
  end
end
