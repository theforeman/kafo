require 'test_helper'

module Kafo
  describe HookContext do
    let(:kafo) { Minitest::Mock.new }
    let(:context) { HookContext.new(kafo) }

    describe "api" do
      specify { assert context.respond_to?(:logger) }
      specify { assert context.respond_to?(:app_option) }
      specify { assert context.respond_to?(:app_value) }
      specify { assert context.respond_to?(:param) }
      specify { assert context.respond_to?(:add_module) }
      specify { assert context.respond_to?(:module_enabled?) }
      specify { assert context.respond_to?(:exit) }
      specify { assert context.respond_to?(:get_custom_config) }
      specify { assert context.respond_to?(:store_custom_config) }
      specify { assert context.respond_to?(:scenario_id) }
      specify { assert context.respond_to?(:scenario_path) }
      specify { assert context.respond_to?(:scenario_data) }
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

    describe "#module_enabled?" do
      specify do
        kafo.expect :module, nil, ['unknown_module']
        assert_equal context.module_enabled?('unknown_module'), false
      end

      specify do
        mod = Minitest::Mock.new
        mod.expect :nil?, false
        mod.expect :enabled?, true
        kafo.expect :module, mod, ['known_module']
        assert_equal context.module_enabled?('known_module'), true
      end
    end
  end
end
