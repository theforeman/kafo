# encoding: UTF-8
require 'highline/import'
require 'kafo_wizards'
require 'pathname'

module Kafo
  class ScenarioManager
    attr_reader :config_dir, :last_scenario_link, :previous_scenario

    def initialize(config, last_scenario_link_name = 'last_scenario.yaml')
      @logger = Logger.new('scenario_manager')
      @config_dir = File.file?(config) ? File.dirname(config) : config
      @last_scenario_link = File.join(config_dir, last_scenario_link_name)
      @previous_scenario = File.exist?(last_scenario_link) ? Pathname.new(last_scenario_link).realpath.to_s : nil
    end

    def available_scenarios
      # assume that *.yaml file in config_dir that has key :name is scenario definition
      @available_scenarios ||= Dir.glob(File.join(config_dir, '*.yaml')).reject { |f| f =~ /#{last_scenario_link}$/ }.inject({}) do |scns, scn_file|
        begin
          content = YAML.load_file(scn_file)
          if content.is_a?(Hash) && content.has_key?(:answer_file) && content.fetch(:enabled, true)
            # add scenario name for legacy configs
            content[:name] = Configuration.get_scenario_id(scn_file) unless content.has_key?(:name)
            scns[scn_file] = content
          end
        rescue Psych::SyntaxError => e
          warn "Warning: #{e}"
        end
        scns
      end
    end

    def list_available_scenarios
      say ::HighLine.color("Available scenarios", :info)
      available_scenarios.each do |config_file, content|
        scenario = File.basename(config_file, '.yaml')
        use = ((File.expand_path(config_file) == @previous_scenario) ? 'INSTALLED' : "use: --scenario #{scenario}")
        say ::HighLine.color("  #{content[:name]} ", :title)
        say "(#{use})"
        say "        " + content[:description] if !content[:description].nil? && !content[:description].empty?
      end
      say "  No available scenarios found in #{config_dir}" if available_scenarios.empty?
      KafoConfigure.exit(0)
    end

    def scenario_selection_wizard
      wizard = KafoWizards.wizard(:cli, 'Select installation scenario',
        :description => "Please select one of the pre-set installation scenarios. You can customize your setup later during the installation.")
      f = wizard.factory
      available_scenarios.keys.each do |scn|
        label = available_scenarios[scn][:name].to_s
        label += ": #{available_scenarios[scn][:description]}" if available_scenarios[scn][:description]
        wizard.entries << f.button(scn, :label => label, :default => true)
      end
      wizard.entries << f.button(:cancel, :label => 'Cancel Installation', :default => false)
      wizard
    end

    def select_scenario_interactively
      # let the user select if in interactive mode
      if (ARGV & ['--interactive', '-i']).any?
        res = scenario_selection_wizard.run
        if res == :cancel
          say 'Installation was cancelled by user'
          KafoConfigure.exit(0)
        end
        res
      end
    end

    def scenario_changed?(scenario)
      scenario = Pathname.new(scenario).realpath.to_s if File.symlink?(scenario)
      !!previous_scenario && scenario != previous_scenario
    end

    def configured?
      !!(defined?(CONFIG_DIR) && CONFIG_DIR)
    end

    def scenario_from_args(arg_name = '--scenario|-S')
      # try scenario provided in the args via -S or --scenario
      ARGV.each_with_index do |arg, index|
        parsed = arg.match(/^(#{arg_name})($|=(?<scenario>\S+))/)
        if parsed
          scenario = parsed[:scenario] || ARGV[index + 1]
          next unless scenario

          scenario_file = File.join(config_dir, "#{scenario}.yaml")
          return scenario_file if File.exist?(scenario_file)
          fail_now("Scenario (#{scenario_file}) was not found, can not continue", :unset_scenario)
        end
      end

      nil
    end

    def select_scenario
      scenario = scenario_from_args || previous_scenario ||
        (available_scenarios.keys.count == 1 && available_scenarios.keys.first) ||
        select_scenario_interactively
      if scenario.nil?
        fail_now("No installation scenario was selected, the installer cannot continue.\n" +
          "       Even --help content is dependent on selected scenario.\n" +
          "       Select scenario with --scenario SCENARIO or list available scenarios with --list-scenarios.", :unset_scenario)
      elsif !scenario_enabled?(scenario)
        fail_now("Selected scenario is DISABLED, can not continue.\n" +
          "       Use --list-scenarios to list available options.\n" +
          "       You can also --enable-scenario SCENARIO to make the selected scenario available.", :scenario_error)
      end
      scenario
    end

    def show_scenario_diff(prev_scenario, new_scenario)
      say ::HighLine.color("Scenarios are being compared, that may take a while...", :info)
      prev_conf = load_and_setup_configuration(prev_scenario)
      new_conf = load_and_setup_configuration(new_scenario)
      print_scenario_diff(prev_conf, new_conf)
    end

    def check_scenario_change(scenario)
      if scenario_changed?(scenario)
        if ARGV.include? '--compare-scenarios'
          show_scenario_diff(@previous_scenario, scenario)
          dump_log_and_exit(0)
        else
          confirm_scenario_change(scenario)
          @logger.notice "Scenario #{scenario} was selected"
        end
      end
    end

    def check_enable_scenario
      scenario = scenario_from_args('--enable-scenario')
      set_scenario_availability(scenario, true) if scenario
    end

    def check_disable_scenario
      scenario = scenario_from_args('--disable-scenario')
      set_scenario_availability(scenario, false) if scenario
    end

    def set_scenario_availability(scenario, available)
      cfg = load_configuration(scenario)
      cfg.app[:enabled] = available
      cfg.save_configuration(cfg.app)
      say "Scenario #{File.basename(scenario, ".yaml")} was #{available ? "enabled" : "disabled"}"
      KafoConfigure.exit(0)
    end

    def scenario_enabled?(scenario)
      load_configuration(scenario).app[:enabled]
    end

    def confirm_scenario_change(new_scenario)
      if (ARGV & ['--interactive', '-i']).any?
        show_scenario_diff(@previous_scenario, new_scenario)

        wizard = KafoWizards.wizard(:cli, 'Confirm installation scenario selection',
          :description => "You are trying to replace an existing installation with a different scenario. This may lead to unpredictable states. Please confirm that you want to proceed.")
        wizard.entries << wizard.factory.button(:proceed, :label => 'Proceed with selected installation scenario', :default => false)
        wizard.entries << wizard.factory.button(:cancel, :label => 'Cancel Installation', :default => true)
        result = wizard.run
        if result == :cancel
          say 'Installation was cancelled by user'
          dump_log_and_exit(0)
        end
      elsif !ARGV.include?('--force') && !KafoConfigure.in_help_mode?
        message = "You are trying to replace existing installation with different scenario. This may lead to unpredictable states. " +
        "Use --force to override. You can use --compare-scenarios to see the differences"
        @logger.error(message)
        dump_log_and_exit(:scenario_error)
      end
      true
    end

    def print_scenario_diff(prev_conf, new_conf)
      missing = new_conf.params_missing(prev_conf)
      changed = new_conf.params_changed(prev_conf)

      say "\n" + ::HighLine.color("Overview of modules used in the scenarios (#{prev_conf.app[:name]} -> #{new_conf.app[:name]}):", :title)
      modules = Hash.new { |h, k| h[k] = {} }
      modules = prev_conf.modules.inject(modules) { |mods, mod| mods[mod.name][:prev] = mod.enabled?; mods }
      modules = new_conf.modules.inject(modules) { |mods, mod| mods[mod.name][:new] = mod.enabled?; mods }
      printables = { "" => 'N/A', 'true' => 'ENABLED', 'false' => 'DISABLED' }
      modules.each do |mod, status|
        module_line = "%-50s: %-09s -> %s" % [mod, printables[status[:prev].to_s], printables[status[:new].to_s]]
        # highlight modules that will be disabled
        module_line = ::HighLine.color(module_line, :important) if status[:prev] == true && (status[:new] == false || status[:new].nil?)
        say module_line
      end

      say "\n" + ::HighLine.color("Defaults that will be updated with values from previous installation:", :title)
      if changed.empty?
        say "  No values will be updated from previous scenario"
      else
        changed.each { |param| say "  #{param.module.class_name}::#{param.name}: #{param.value} -> #{prev_conf.param(param.module.class_name, param.name).value}" }
      end
      say "\n" + ::HighLine.color("Values from previous installation that will be lost by scenario change:", :title)
      if missing.empty?
        say "  No values from previous installation will be lost"
      else
        missing.each { |param| say "  #{param.module.class_name}::#{param.name}: #{param.value}\n" }
      end
    end

    def link_last_scenario(config_file)
      link_path = last_scenario_link
      if link_path
        File.delete(link_path) if File.symlink?(link_path)
        File.symlink(File.basename(config_file), link_path)
      end
    end

    def load_and_setup_configuration(config_file)
      conf = load_configuration(config_file)
      conf.preset_defaults_from_puppet
      conf.preset_defaults_from_yaml
      conf
    end

    def load_configuration(config_file)
      Configuration.new(config_file)
    end

    private

    def fail_now(message, exit_code)
      $stderr.puts "ERROR: #{message}"
      @logger.error message
      KafoConfigure.exit(exit_code)
    end

    def dump_log_and_exit(code)
      if Logging.buffering? && Logging.buffer.any?
        if !KafoConfigure.config.nil?
          Logging.setup(verbose: true)
          @logger.notice("Log was be written to #{KafoConfigure.config.log_file}")
        end
        @logger.notice('Logs flushed')
      end
      KafoConfigure.exit(code)
    end
  end
end
