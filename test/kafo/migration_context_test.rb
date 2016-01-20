require 'test_helper'

module Kafo
  describe MigrationContext do
    let(:context) { MigrationContext.new({}, {}) }

    describe "api" do
      specify { context.respond_to?(:logger) }
      specify { context.respond_to?(:scenario) }
      specify { context.respond_to?(:answers) }
    end
  end
end
