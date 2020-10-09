require 'test_helper'

module Kafo
  describe HookContext do
    let(:kafo) { Minitest::Mock.new }
    let(:logger) { Minitest::Mock.new }
    let(:context) { HookContext.new(kafo, logger) }

    describe "api" do
      specify { assert context.respond_to?(:logger) }
      specify { assert context.respond_to?(:app_option) }
      specify { assert context.respond_to?(:app_option?) }
      specify { assert context.respond_to?(:app_value) }
      specify { assert context.respond_to?(:param) }
      specify { assert context.respond_to?(:add_module) }
      specify { assert context.respond_to?(:module_enabled?) }
      specify { assert context.respond_to?(:module_present?) }
      specify { assert context.respond_to?(:exit) }
      specify { assert context.respond_to?(:get_custom_config) }
      specify { assert context.respond_to?(:store_custom_config) }
      specify { assert context.respond_to?(:has_custom_fact?) }
      specify { assert context.respond_to?(:scenario_id) }
      specify { assert context.respond_to?(:scenario_path) }
      specify { assert context.respond_to?(:scenario_data) }
      specify { assert context.respond_to?(:exit_code) }
    end

    describe "#scenario_data" do
      specify do
        config = Minitest::Mock.new
        kafo.expect :config, config
        config.expect :app, {'foo' => 'bar'}
        assert_equal({'foo' => 'bar'}, context.scenario_data)
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

    describe "#module_present?" do
      specify do
        kafo.expect :module, nil, ['unknown_module']
        assert_equal context.module_present?('unknown_module'), false
      end

      specify do
        mod = Minitest::Mock.new
        mod.expect :nil?, false
        mod.expect :enabled?, true
        kafo.expect :module, mod, ['enabled_module']
        assert_equal context.module_present?('enabled_module'), true
      end

      specify do
        mod = Minitest::Mock.new
        mod.expect :nil?, false
        mod.expect :enabled?, false
        kafo.expect :module, mod, ['disabled_module']
        assert_equal context.module_present?('disabled_module'), true
      end
    end

    describe "#app_option?" do
      let(:app) { {:known_option => 'option_arg'} }
      let(:config) { Minitest::Mock.new }

      specify do
        kafo.expect :config, config
        config.expect :app, app
        assert_equal true, context.app_option?('known_option')
      end

      specify do
        kafo.expect :config, config
        config.expect :app, app
        assert_equal false, context.app_option?('unknown_option')
      end
    end

    describe "#has_custom_fact? with fact value present" do
      let(:config) { Minitest::Mock.new }
      let(:custom_fact_storage) { { 'my_custom_fact' => 'my_custom_fact_value' } }

      specify do
        kafo.expect :config, config
        config.expect :has_custom_fact?, true, ['my_custom_fact']
        assert_equal true, context.has_custom_fact?('my_custom_fact')
      end

      specify do
        kafo.expect :config, config
        config.expect :has_custom_fact?, false, ['not_my_custom_fact']
        assert_equal false, context.has_custom_fact?('not_my_custom_fact')
      end
    end

    describe "#has_custom_fact? with fact value nil" do
      let(:config) { Minitest::Mock.new }
      let(:custom_fact_storage) { { 'my_custom_fact' => nil } }

      specify do
        kafo.expect :config, config
        config.expect :has_custom_fact?, true, ['my_custom_fact']
        assert_equal true, context.has_custom_fact?('my_custom_fact')
      end

      specify do
        kafo.expect :config, config
        config.expect :has_custom_fact?, false, ['not_my_custom_fact']
        assert_equal false, context.has_custom_fact?('not_my_custom_fact')
      end
    end

    describe "#exit_code " do
      let(:config) { Minitest::Mock.new }

      specify do
        kafo.expect :exit_code, 0
        assert_equal 0, context.exit_code
      end
    end
  end
end
