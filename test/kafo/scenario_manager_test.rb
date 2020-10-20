require 'test_helper'
require 'fileutils'
require 'tmpdir'

module Kafo
  describe ScenarioManager do
    let(:manager) { ScenarioManager.new('/path/to/scenarios.d') }
    let(:manager_with_file) { ScenarioManager.new('/path/to/scenarios.d/foreman.yaml') }
    let(:input) { StringIO.new }
    let(:output) { StringIO.new }
    before do
      ColorScheme.new(:colors => false).setup
      new_instance = ::HighLine.new(input, output)
      if ::HighLine.respond_to?(:default_instance)
        @old_default = ::HighLine.default_instance
        ::HighLine.default_instance = new_instance
      else
        @old_default = $terminal
        $terminal = new_instance
      end
    end

    after do
      if ::HighLine.respond_to?(:default_instance)
        ::HighLine.default_instance = @old_default
      else
        $terminal = @old_default
      end
    end

    describe "#config_dir" do
      specify { _(manager.config_dir).must_equal '/path/to/scenarios.d' }

      it "supports old configuration" do
        File.stub(:file?, true) do
          _(manager_with_file.config_dir).must_equal '/path/to/scenarios.d'
        end
      end
    end

    describe "#initialize" do
      describe "with last_scenario.yaml" do
        let(:tmpdir) { Dir.mktmpdir }
        let(:scenario_path) { File.join(tmpdir, 'foreman.yaml') }

        before do
          FileUtils.touch(scenario_path)
          FileUtils.ln_s('foreman.yaml', File.join(tmpdir, 'last_scenario.yaml'))
        end
        after { FileUtils.remove_entry_secure tmpdir }

        it "determines path to last scenario" do
          _(ScenarioManager.new(tmpdir).previous_scenario).must_equal scenario_path
        end
      end
    end

    describe "#last_scenario_link" do
      specify { _(manager.last_scenario_link).must_equal '/path/to/scenarios.d/last_scenario.yaml' }
    end

    describe "#link_last_scenario" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:scenario1_path) { File.join(tmpdir, 'foreman1.yaml') }
      let(:scenario2_path) { File.join(tmpdir, 'foreman2.yaml') }
      let(:last_path) { File.join(tmpdir, 'linked_scenario.yaml') }

      before do
        FileUtils.touch([scenario1_path, scenario2_path])
        FileUtils.ln_s(last_target, last_path)
      end
      after { FileUtils.remove_entry_secure tmpdir }

      describe "with existing symlink" do
        let(:last_target) { 'foreman1.yaml' }
        specify do
          manager.stub(:last_scenario_link, last_path) { manager.link_last_scenario(scenario2_path) }
          _(File.readlink(last_path)).must_equal 'foreman2.yaml'
          _(File.exist?(last_path)).must_equal true
        end
      end

      describe "with broken symlink" do
        let(:last_target) { 'unknown.yaml' }
        specify do
          manager.stub(:last_scenario_link, last_path) { manager.link_last_scenario(scenario1_path) }
          _(File.readlink(last_path)).must_equal 'foreman1.yaml'
          _(File.exist?(last_path)).must_equal true
        end
      end
    end

    describe "#scenario_changed?" do
      it "detects changed scenario" do
        manager.stub(:previous_scenario, '/path/to/scenarios.d/last.yaml') do
          _(manager.scenario_changed?('/path/to/scenarios.d/foreman.yaml')).must_equal true
        end
      end

      it "detects unchanged scenario" do
        manager.stub(:previous_scenario, '/path/to/scenarios.d/foreman.yaml') do
          _(manager.scenario_changed?('/path/to/scenarios.d/foreman.yaml')).must_equal false
        end
      end

      specify { _(manager.scenario_changed?('/path/to/scenarios.d/foreman.yaml')).must_equal false }

      describe "with symlink" do
        let(:tmpdir) { Dir.mktmpdir }
        let(:scenario_path) { File.join(tmpdir, 'foreman.yaml') }

        before do
          FileUtils.touch(scenario_path)
          FileUtils.ln_s('foreman.yaml', File.join(tmpdir, 'linked_foreman.yaml'))
        end
        after { FileUtils.remove_entry_secure tmpdir }

        it "detects unchanged scenario" do
          manager.stub(:previous_scenario, scenario_path) do
            _(manager.scenario_changed?(File.join(tmpdir, 'linked_foreman.yaml'))).must_equal false
          end
        end
      end
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
        _(create_and_load_scenarios(scn.to_yaml).keys.count).must_equal 1
      end

      it 'skips scenarios without answer file' do
        yaml_file = { :this_is => 'Not a scenario' }
        _(create_and_load_scenarios(yaml_file.to_yaml).keys).must_be_empty
      end

      it 'skips disabled scenarios' do
        scn = { :name => 'Second', :description => 'Second scenario', :answer_file => '', :enabled => false }
        _(create_and_load_scenarios(scn.to_yaml).keys).must_be_empty
      end

      it 'skips non-yaml files' do
        _(create_and_load_scenarios('some text file', 'text.txt').keys).must_be_empty
      end
    end

    describe "#list_available_scenarios" do
      let(:available_scenarios) do
        {
          '/path/first.yaml' => { :name => 'First', :description => 'First scenario'},
          '/path/second.yaml' => { :name => 'Second', :description => 'Second scenario'}
        }
      end
      before do
        ColorScheme.new(:colors => false).setup
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
      before do
        ColorScheme.new(:colors => false).setup
      end

      it 'fails if disabled scenario is selected' do
        error_text = with_captured_stderr do
          disabled_answers = ConfigFileFactory.build_answers('disabled', {}.to_yaml)
          disabled_scn = { :name => 'Disabled', :description => 'Disabled scenario', :answer_file => disabled_answers.path, :enabled => false }
          scn_file = ConfigFileFactory.build('disabled', disabled_scn.to_yaml).path

          manager.stub(:scenario_from_args, scn_file) do
            must_exit_with_code(:scenario_error) { manager.select_scenario }
          end
        end
        assert_match(/ERROR: Selected scenario is DISABLED, can not continue/, error_text)
      end
    end

    describe '#scenario_from_args' do
      before do
        @old_argv = ::ARGV.dup
        ::ARGV.clear
        ::ARGV.concat(args)
      end
      after do
        ::ARGV.clear
        ::ARGV.concat(@old_argv)
      end

      describe 'with -S inside a word' do
        let(:args) { ['--server-ca', 'A-ST.pem'] }

        it 'ignores -S inside words' do
          manager.stub(:fail_now, Proc.new { |message, _| raise message }) do
            assert_nil manager.scenario_from_args
          end
        end
      end

      [
        ['-S', 'myscenario'],
        ['-S=myscenario'],
        ['--scenario', 'myscenario'],
        ['--scenario=myscenario'],
      ].each do |argsx|
        describe "with #{argsx.inspect}" do
          let(:args) { argsx }

          it 'finds myscenario' do
            manager.stub(:fail_now, Proc.new { |message, _| raise message }) do
              filename = File.join(manager.config_dir, 'myscenario.yaml')
              File.stub(:exist?, true, filename) do
                assert_equal filename, manager.scenario_from_args
              end
            end
          end
        end
      end
    end

    describe '#confirm_scenario_change' do
      let(:basic_config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
      let(:new_config) { Kafo::Configuration.new(basic_config_file, false) }

      before :all do
        @argv = ARGV
        ARGV.clear
      end

      after :all do
        ARGV.clear
        ARGV.concat(@argv)
      end

      it 'prints error and exits when not forced' do
        must_exit_with_code(Kafo::ExitHandler.new.error_codes[:scenario_error]) do
          manager.confirm_scenario_change(new_config)
        end

        KafoConfigure.stub :exit, 0 do
          out, _ = capture_subprocess_io { manager.confirm_scenario_change(new_config) }

          _(out).must_match(/You are trying to replace existing installation with different scenario. This may lead to unpredictable states. Use --force to override. You can use --compare-scenarios to see the differences/)
        end
      end

      it 'passes when forced (--force)' do
        ARGV << '--force'
        assert manager.confirm_scenario_change(new_config)
      end

      it 'passes when printing help (--help)' do
        ARGV << '--help'
        assert manager.confirm_scenario_change(new_config)
      end

      it 'passes when printing full help (--full-help)' do
        ARGV << '--full-help'
        assert manager.confirm_scenario_change(new_config)
      end

      it 'passes when printing help (-h)' do
        ARGV << '-h'
        assert manager.confirm_scenario_change(new_config)
      end
    end

    describe '#print_scenario_diff' do
      let(:basic_config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
      let(:new_config) { Kafo::Configuration.new(basic_config_file, false) }
      let(:old_config) { Kafo::Configuration.new(basic_config_file, false) }

      let(:p_foo) { fake_param('foo', 1) }
      let(:p_bar) { fake_param('bar', 10) }
      let(:p_baz) { fake_param('baz', 100) }
      let(:p_old_foo) { fake_param('foo', 2) }
      let(:p_old_bar) { fake_param('bar', 10) }
      let(:p_old_baz) { fake_param('baz', 100) }

      it 'prints no updates' do
        old_config.stub(:modules, [fake_module('mod', [p_old_bar])]) do
          new_config.stub(:modules, [fake_module('mod', [p_bar])]) do
            manager.print_scenario_diff(old_config, new_config)
            must_be_on_stdout(output, "No values will be updated from")
            must_be_on_stdout(output, "previous scenario\n")
          end
        end
      end

      it 'prints updated_values' do
        old_config.stub(:modules, [fake_module('mod', [p_old_foo, p_old_bar])]) do
          new_config.stub(:modules, [fake_module('mod', [p_foo, p_bar])]) do
            manager.print_scenario_diff(old_config, new_config)
            must_be_on_stdout(output, "mod::foo: 1 -> 2\n")
          end
        end
      end

      it 'print no loses' do
        old_config.stub(:modules, []) do
          new_config.stub(:modules, []) do
            manager.print_scenario_diff(old_config, new_config)
            must_be_on_stdout(output, "No values from previous installation")
            must_be_on_stdout(output, "will be lost\n")
          end
        end
      end

      it 'prints values that will be lost' do
        old_config.stub(:modules, [fake_module('mod', [p_old_baz])]) do
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
