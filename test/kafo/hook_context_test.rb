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
      specify { context.respond_to?(:exit).must_equal true }
      specify { context.respond_to?(:get_custom_config).must_equal true }
      specify { context.respond_to?(:store_custom_config).must_equal true }
      specify { context.respond_to?(:scenario_path).must_equal true }
      specify { context.respond_to?(:scenario_data).must_equal true }
    end

    describe "#scenario_data" do
      specify do
        Tempfile.open('scenario') do |file|
          file.write(YAML.dump({'foo' => 'bar'}))
          file.flush

          context.stub :scenario_path, file.path do
            assert_equal context.scenario_data, {'foo' => 'bar'}
          end
        end
      end
    end
  end
end
