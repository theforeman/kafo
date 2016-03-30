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

    describe "#available_scenarios" do
      def create_and_load_scenarios(content, filename='default.yaml')
        Dir.mktmpdir do |dir|
          File.open(File.join(dir, filename), 'w') { |f| f.write(content) }
          ScenarioManager.new(dir).available_scenarios
        end
      end

      it 'collects valid scenarios' do
        scn = { :name => 'First', :description => 'First scenario', :answer_file => ''}
        create_and_load_scenarios(scn.to_yaml).keys.count.must_equal 1
      end

      it 'skips scenarios without answer file' do
        yaml_file = { :this_is => 'Not a scenario' }
        create_and_load_scenarios(yaml_file.to_yaml).keys.must_be_empty
      end

      it 'skips disabled scenarios' do
        scn = { :name => 'Second', :description => 'Second scenario', :answer_file => '', :enabled => false }
        create_and_load_scenarios(scn.to_yaml).keys.must_be_empty
      end

      it 'skips non-yaml files' do
        create_and_load_scenarios('some text file', 'text.txt').keys.must_be_empty
      end
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

    describe '#select_scenario' do
      let(:input) { StringIO.new }
      let(:output) { StringIO.new }
      before do
        $terminal.instance_variable_set '@output', output
      end

      it 'fails if disabled scenario is selected' do
        disabled_answers = ConfigFileFactory.build_answers('disabled', {}.to_yaml)
        disabled_scn = { :name => 'Disabled', :description => 'Disabled scenario', :answer_file => disabled_answers.path, :enabled => false }
        scn_file = ConfigFileFactory.build('disabled', disabled_scn.to_yaml).path

        manager.stub(:scenario_from_args, scn_file) do
          must_exit_with_code(:scenario_error) { manager.select_scenario }
          must_be_on_stdout(output, 'Selected scenario is DISABLED, can not continue.')
          must_be_on_stdout(output, 'Use --list-scenarios to list available options.')
          must_be_on_stdout(output, 'You can also --enable-scenario SCENARIO to make the selected scenario available.')
        end
      end
    end

    describe '#print_scenario_diff' do
      let(:basic_config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
      let(:new_config) { Kafo::Configuration.new(basic_config_file, false) }
      let(:old_config) { Kafo::Configuration.new(basic_config_file, false) }

      let(:p_foo) { fake_param('mod', 'foo', 1) }
      let(:p_bar) { fake_param('mod', 'bar', 10) }
      let(:p_baz) { fake_param('mod', 'baz', 100) }
      let(:p_old_foo) { fake_param('mod', 'foo', 2) }
      let(:p_old_bar) { fake_param('mod', 'bar', 10) }
      let(:p_old_baz) { fake_param('mod', 'baz', 100) }

      let(:input) { StringIO.new }
      let(:output) { StringIO.new }
      before do
        $terminal.instance_variable_set '@output', output
      end

      it 'prints no updates' do
        old_config.stub(:params, [p_old_bar]) do
          old_config.stub(:modules, []) do
            new_config.stub(:params, [p_bar]) do
              new_config.stub(:modules, []) do
                manager.print_scenario_diff(old_config, new_config)
                must_be_on_stdout(output, "No values will be updated from previous scenario\n")
              end
            end
          end
        end
      end

      it 'prints updated_values' do
        old_config.stub(:params, [p_old_foo, p_old_bar]) do
          old_config.stub(:modules, []) do
            new_config.stub(:params, [p_foo, p_bar]) do
              new_config.stub(:modules, []) do
                manager.print_scenario_diff(old_config, new_config)
                must_be_on_stdout(output, "mod::foo: 1 -> 2\n")
                end
              end
          end
        end
      end

      it 'print no loses' do
        old_config.stub(:params, []) do
          old_config.stub(:modules, []) do
            new_config.stub(:params, []) do
              new_config.stub(:modules, []) do
                manager.print_scenario_diff(old_config, new_config)
                must_be_on_stdout(output, "No values from previous installation will be lost\n")
              end
            end
          end
        end
      end

      it 'prints values that will be lost' do
        old_config.stub(:params, [p_old_baz]) do
          old_config.stub(:modules, []) do
            new_config.stub(:params, []) do
              new_config.stub(:modules, []) do
                new_config.stub(:module_enabled?, true) do
                  manager.print_scenario_diff(old_config, new_config)
                  must_be_on_stdout(output, "mod::baz: 100\n")
                end
              end
            end
          end
        end
      end
    end

  end
end
