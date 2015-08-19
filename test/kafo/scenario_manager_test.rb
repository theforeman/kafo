require 'test_helper'

module Kafo
  describe ScenarioManager do
    let(:manager) { ScenarioManager.new('/path/to/scenarios.d') }
    let(:manager_with_file) { ScenarioManager.new('/path/to/scenarios.d/foreman.yaml') }

    describe "#config_dir" do
      specify { manager.config_dir.must_equal '/path/to/scenarios.d' }

      it "supports old configuration" do
        File.stub(:file?, true) do
          manager_with_file.config_dir.must_equal '/path/to/scenarios.d'
        end
      end
    end

    describe "#last_scenario_link" do
      specify { manager.last_scenario_link.must_equal '/path/to/scenarios.d/last_scenario.yaml' }
    end

    describe "#scenario_changed?" do
      it "detects changed scenario" do
        manager.stub(:previous_scenario, '/path/to/scenarios.d/last.yaml') do
          manager.scenario_changed?('/path/to/scenarios.d/foreman.yaml').must_equal true
        end
      end

      it "detects unchanged scenario" do
        manager.stub(:previous_scenario, '/path/to/scenarios.d/foreman.yaml') do
          manager.scenario_changed?('/path/to/scenarios.d/foreman.yaml').must_equal false
        end
      end

      specify { manager.scenario_changed?('/path/to/scenarios.d/foreman.yaml').must_equal false }
    end

    describe "#list_available_scenarios" do
      let(:input) { StringIO.new }
      let(:output) { StringIO.new }
      let(:available_scenarios) do
        {
          '/path/first.yaml' => { :name => 'First', :description => 'First scenario'},
          '/path/second.yaml' => { :name => 'Second', :description => 'Second scenario'}
        }
      end
      before do
        $terminal.instance_variable_set '@output', output
      end

      it "prints available scenarios" do
        manager.stub(:available_scenarios, available_scenarios) do
          must_exit_with_code(0) { manager.list_available_scenarios }
          must_be_on_stdout(output, 'First (use: --scenario first)')
          must_be_on_stdout(output, 'Second (use: --scenario second)')
        end
      end

      it "prints no available scenarios" do
        manager.stub(:available_scenarios, {}) do
          must_exit_with_code(0) { manager.list_available_scenarios }
          must_be_on_stdout(output, 'No available scenarios found')
        end
      end
    end

  end
end
