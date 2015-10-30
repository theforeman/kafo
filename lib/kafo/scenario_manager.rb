# encoding: UTF-8
require 'kafo_wizards'

module Kafo
  class ScenarioManager
    attr_reader :config_dir, :last_scenario_link, :previous_scenario

    def initialize(config, last_scenario_link_name='last_scenario.yaml')
      @config_dir = File.file?(config) ? File.dirname(config) : config
      @last_scenario_link = File.join(config_dir, last_scenario_link_name)
      @previous_scenario = File.realpath(last_scenario_link) if File.exists?(last_scenario_link)
    end

    def available_scenarios
      # assume that *.yaml file in config_dir that has key :name is scenario definition
      @available_scenarios ||= Dir.glob(File.join(config_dir, '*.yaml')).reject { |f| f =~ /#{last_scenario_link}$/ }.inject({}) do |scns, scn_file|
        begin
          content = YAML.load_file(scn_file)
          if content.is_a?(Hash) && content.has_key?(:answer_file)
            # add scenario name for legacy configs
            content[:name] = File.basename(scn_file, '.yaml') unless content.has_key?(:name)
            scns[scn_file] = content
          end
        rescue Psych::SyntaxError => e
          warn "Warning: #{e}"
        end
        scns
      end
    end

    def list_available_scenarios
      say "Available scenarios"
      available_scenarios.each do |config_file, content|
        scenario = File.basename(config_file, '.yaml')
        say "  #{content[:name]} (use: --scenario #{scenario})"
        say "        " + content[:description] unless (content[:description].nil? || content[:description].empty?)
      end
      say "  No available scenarios found in #{config_dir}" if available_scenarios.empty?
      KafoConfigure.exit(0)
    end


    def scenario_selection_wizard
      wizard = KafoWizards.wizard(:cli, 'Select installation scenario',
        :description => "Please select one of the pre-set installation scenarios. You can customize your installtion later during the installtion.")
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
      scenario = File.realpath(scenario) if File.symlink?(scenario)
      !!previous_scenario && scenario != previous_scenario
    end

    def configured?
      !!(defined?(CONFIG_DIR) && CONFIG_DIR)
    end

    def select_scenario
      scenario = scenario_from_args || previous_scenario ||
        (available_scenarios.keys.count == 1 && available_scenarios.keys.first) ||
        select_scenario_interactively
      if scenario.nil?
        fail_now("Scenario was not selected, can not continue. Use --list-scenarios to list available options.", :unknown_scenario)
      else
        # check if scenario was changed
        confirm_scenario_change(scenario) if scenario_changed?(scenario)
      end
      KafoConfigure.logger.info "Scenario #{scenario} was selected"
      scenario
    end

    def scenario_from_args
      # try scenario provided in the args via -S or --scenario
      parsed = ARGV.join(" ").match /(--scenario|-S)(\s+|[=]?)(\S+)/
      if parsed
        scenario_file = File.join(config_dir, "#{parsed[3]}.yaml")
        return scenario_file if File.exists?(scenario_file)
        fail_now("Scenario (#{scenario_file}) was not found, can not continue", :unknown_scenario)
      end
    end

    def confirm_scenario_change(new_scenario)
      if (ARGV & ['--interactive', '-i']).any?
        # TODO: show option diff
        wizard = KafoWizards.wizard(:cli, 'Confirm installation scenario selection',
          :description => "You are trying to replace existing installation with different scenario. This may lead to unpredictable states. Please confirm that you want to proceed.")
        wizard.entries << wizard.factory.button(:proceed, :label => 'Proceed with selected installation scenario', :default => false)
        wizard.entries << wizard.factory.button(:cancel, :label => 'Cancel Installation', :default => true)
        result = wizard.run
        if result == :cancel
          say 'Installation was cancelled by user'
          KafoConfigure.exit(0)
        end
      else
        if ARGV.include?('--force')
          message = "You are trying to replace existing installation with different scenario. This may lead to unpredictable states. Use --force to override."
          fail_now(message,:scenario_error)
        end
      end
    end

    def link_last_scenario(config_file)
      link_path = last_scenario_link
      if last_scenario_link
        File.delete(last_scenario_link) if File.exist?(last_scenario_link)
        File.symlink(config_file, last_scenario_link)
      end
    end

    private

    def fail_now(message, exit_code)
      say "ERROR: #{message}"
      KafoConfigure.logger.error message
      KafoConfigure.exit(exit_code)
    end
  end
end
