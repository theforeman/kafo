# encoding: UTF-8

# First of all we have to store ENV variable, requiring facter can override them
module Kafo
  module ENV
    LANG = ::ENV['LANG']
  end
end

require 'pty'
require 'clamp'
require 'kafo/color_scheme'
require 'kafo_parsers/exceptions'
require 'kafo/exceptions'
require 'kafo/migrations'
require 'kafo/store'
require 'kafo/configuration'
require 'kafo/logger'
require 'kafo/string_helper'
require 'kafo/help_builder'
require 'kafo/wizard'
require 'kafo/system_checker'
require 'kafo/puppet_command'
require 'kafo/puppet_log_parser'
require 'kafo/progress_bar'
require 'kafo/hooking'
require 'kafo/exit_handler'
require 'kafo/scenario_manager'
require 'kafo/execution_environment'
require 'kafo/logging'

module Kafo
  class KafoConfigure < Clamp::Command
    include StringHelper

    class << self
      attr_accessor :config, :root_dir, :config_file, :gem_root,
                    :module_dirs, :kafo_modules_dir, :verbose, :app_options, :logger,
                    :check_dirs, :exit_handler, :scenario_manager, :store
      attr_writer :hooking

      def hooking
        @hooking ||= Hooking.new
      end
    end

    def initialize(*args)
      self.class.preset_color_scheme
      self.class.logger           = Logger.new
      self.class.exit_handler     = ExitHandler.new
      @progress_bar               = nil
      @config_reload_requested    = false

      scenario_manager = setup_scenario_manager
      self.class.scenario_manager = scenario_manager

      # Handle --list-scenarios before we need them
      scenario_manager.list_available_scenarios if ARGV.include?('--list-scenarios')
      scenario_manager.check_enable_scenario
      scenario_manager.check_disable_scenario
      setup_config(config_file)

      self.class.hooking.execute(:pre_migrations)
      reload_config
      applied_total = self.class.config.run_migrations
      request_config_reload if applied_total > 0

      if ARGV.include?('--migrations-only')
        verbose = (ARGV.include?('--verbose') || ARGV.include?('-v'))
        Logging.setup(verbose: verbose)
        self.class.logger.notice('Log buffers flushed')
        self.class.exit(0)
      end

      reload_config

      if scenario_manager.configured?
        scenario_manager.check_scenario_change(self.class.config_file)
        if scenario_manager.scenario_changed?(self.class.config_file) && !self.class.in_help_mode?
          prev_config = scenario_manager.load_configuration(scenario_manager.previous_scenario)
          prev_config.run_migrations
          self.class.config.migrate_configuration(prev_config, :skip => [:log_name])
          setup_config(self.class.config_file)
          self.class.logger.notice("Due to scenario change the configuration (#{self.class.config_file}) was updated with #{scenario_manager.previous_scenario} and reloaded.")
        end
      end

      super

      self.class.hooking.execute(:boot)
      set_app_options # define args for installer
      # we need to parse app config params using clamp even before run method does it
      # so we limit parsing only to app config options (because of --help and later defined params)
      parse clamp_app_arguments
      parse_app_arguments # set values from ARGS to config.app
      self.config.configure_application
      Logging.setup(verbose: config.app[:verbose])
      self.class.set_color_scheme

      self.class.hooking.execute(:init)
      set_parameters # here the params gets parsed and we need app config populated
      set_options
    end

    def config
      self.class.config
    end

    def store
      self.class.store
    end

    def logger
      self.class.logger
    end

    def run(*args)
      started_at = Time.now
      logger.debug("Running installer with args #{args.inspect}")
      super
    ensure
      logger.debug("Installer finished in #{Time.now - started_at} seconds")
    end

    def execute
      parse_cli_arguments

      if !config.app[:verbose]
        @progress_bar = config.app[:colors] ? ProgressBars::Colored.new : ProgressBars::BlackWhite.new
      end

      unless skip_checks_i_know_better?
        unless SystemChecker.check
          puts "Your system does not meet configuration criteria"
          self.class.exit(:invalid_system)
        end
      end

      self.class.hooking.execute(:pre_validations)
      if interactive?
        wizard = Wizard.new(self)
        wizard.run
      else
        unless validate_all
          puts "Error during configuration, exiting"
          self.class.exit(:invalid_values)
        end
      end

      self.class.hooking.execute(:pre_commit)
      unless dont_save_answers? || noop?
        store_params
        self.class.scenario_manager.link_last_scenario(self.class.config_file) if self.class.scenario_manager.configured?
      end
      run_installation
      return self
    rescue SystemExit
      return self
    end

    def self.run
      return super
    rescue SystemExit
      self.exit_handler.exit(self.exit_code) # fail in initialize
    end

    def self.exit(code, &block)
      exit_handler.exit(code, &block)
    end

    def self.exit_code
      self.exit_handler.exit_code
    end

    def self.in_help_mode?
      ARGV.include?('--help') || ARGV.include?('--full-help') || ARGV.include?('-h')
    end

    def exit_code
      self.class.exit_code
    end


    def help
      self.class.help(invocation_path, self)
    end

    def self.help(*args)
      kafo          = args.pop
      builder_class = kafo.full_help? ? HelpBuilders::Advanced : HelpBuilders::Basic
      args.push builder_class.new(kafo.params)
      super(*args)
    end

    def self.app_option(*args, &block)
      self.app_options ||= []
      self.app_options.push self.option(*args, &block)
      self.app_options.last
    end

    def params
      @params ||= modules.map(&:params).flatten
    rescue KafoParsers::ModuleName => e
      puts e
      self.class.exit(:unknown_module)
    end

    def enabled_params
      params.select { |p| p.module.enabled? }
    end

    def reset_params_cache
      @params = nil
      params
    end

    def add_module(name)
      config.add_module(name)
      reset_params_cache
      self.module(name)
    end

    def modules
      config.modules.sort
    end

    def module(name)
      modules.detect { |m| m.name == name }
    end

    def param(mod, name)
      config.param(mod, name)
    end

    def request_config_reload
      @config_reload_requested = true
    end


    private

    def setup_config(conf_file)
      self.class.config_file      = conf_file
      self.class.config           = Configuration.new(self.class.config_file)

      if self.class.config.parser_cache
        self.class.config.parser_cache.force = true if ARGV.include?('--parser-cache')
        self.class.config.parser_cache.force = false if ARGV.include?('--no-parser-cache')
      end

      self.class.root_dir         = self.class.config.root_dir
      self.class.check_dirs       = self.class.config.check_dirs
      self.class.module_dirs      = self.class.config.module_dirs
      self.class.gem_root         = self.class.config.gem_root
      self.class.kafo_modules_dir = self.class.config.kafo_modules_dir
      self.class.hooking.load
      self.class.store            = setup_store
      self.class.hooking.kafo     = self
    end

    def reload_config
      if @config_reload_requested
        scenario_manager = setup_scenario_manager
        self.class.scenario_manager = scenario_manager
        setup_config(self.class.config_file)
        self.class.logger.notice('Installer configuration was reloaded')
        @config_reload_requested = false
      end
    end

    def setup_scenario_manager
      ScenarioManager.new((defined?(CONFIG_DIR) && CONFIG_DIR) || (defined?(CONFIG_FILE) && CONFIG_FILE))
    end

    def setup_store
      store = Store.new()
      store_path = self.class.config.app[:store_dir]
      store_path = File.expand_path(File.join(CONFIG_DIR, '../store.d')) if store_path.empty? && defined?(CONFIG_DIR)
      store.add_dir(store_path) if File.exists?(store_path)
      store
    end

    def set_parameters
      config.preset_defaults_from_puppet
      self.class.hooking.execute(:pre_values)
      config.preset_defaults_from_yaml
      if self.class.scenario_manager.scenario_changed?(config.config_file)
        prev_scenario = self.class.scenario_manager.load_and_setup_configuration(self.class.scenario_manager.previous_scenario)
        config.preset_defaults_from_other_config(prev_scenario)
      end
    end

    def set_app_options
      self.class.app_option ['--[no-]colors'], :flag, 'Use color output on STDOUT',
                            :default => !!config.app[:colors]
      self.class.app_option ['--color-of-background'], 'COLOR', 'Your terminal background is :bright or :dark',
                            :default => config.app[:color_of_background]
      self.class.app_option ['--dont-save-answers'], :flag, "Skip saving answers to '#{self.class.config.answer_file}'?",
                            :default => !!config.app[:dont_save_answers]
      self.class.app_option '--ignore-undocumented', :flag, 'Ignore inconsistent parameter documentation',
                            :default => false
      self.class.app_option ['-i', '--interactive'], :flag, 'Run in interactive mode'
      self.class.app_option '--log-level', 'LEVEL', 'Log level for log file output',
                            :default => config.app[:log_level]
      self.class.app_option ['-n', '--noop'], :flag, 'Run puppet in noop mode?',
                            :default => false
      self.class.app_option ['-p', '--profile'], :flag, 'Run puppet in profile mode?',
                            :default => false
      self.class.app_option ['-s', '--skip-checks-i-know-better'], :flag, 'Skip all system checks', :default => false
      self.class.app_option ['--skip-puppet-version-check'], :flag, 'Skip check for compatible Puppet versions', :default => false
      self.class.app_option ['-v', '--[no-]verbose'], :flag, 'Display log on STDOUT instead of progressbar'
      self.class.app_option ['-l', '--verbose-log-level'], 'LEVEL', 'Log level for verbose mode output',
                            :default => 'notice'
      self.class.app_option ['-S', '--scenario'], 'SCENARIO', 'Use installation scenario'
      self.class.app_option ['--disable-scenario'], 'SCENARIO', 'Disable installation scenario'
      self.class.app_option ['--enable-scenario'], 'SCENARIO', 'Enable installation scenario'
      self.class.app_option ['--list-scenarios'], :flag, 'List available installation scenarios'
      self.class.app_option ['--force'], :flag, 'Force change of installation scenario'
      self.class.app_option ['--compare-scenarios'], :flag, 'Show changes between last used scenario and the scenario specified with -S or --scenario argument'
      self.class.app_option ['--migrations-only'], :flag, 'Apply migrations to a selected scenario and exit'
      self.class.app_option ['--[no-]parser-cache'], :flag, 'Force use or bypass of Puppet module parser cache'
    end

    def set_options
      self.class.option '--full-help', :flag, "print complete help" do
        @full_help = true
        request_help
      end

      modules.each do |mod|
        self.class.option d("--[no-]enable-#{mod.name}"),
                          :flag,
                          "Enable '#{mod.name}' puppet module",
                          :default => mod.enabled?
      end

      params.sort.each do |param|
        doc = param.doc.nil? ? 'UNDOCUMENTED' : param.doc.join("\n")
        self.class.option parametrize(param), '', doc + " (current: #{param.value_to_s})",
                          :multivalued => param.multivalued?
        self.class.option parametrize(param, 'reset-'), :flag,
                          "Reset #{param.name} to the default value (#{param.default_to_s})"
      end
    end

    # ARGV can contain values for attributes e.g. ['-l', 'info']
    # so we accept either allowed args or those that does not start with '-' and are right after
    # accepted argument
    def clamp_app_arguments
      @allowed_clamp_app_arguments = self.class.app_options.map do |option|
        option.switches.map { |s| is_yes_no_flag?(s) ? build_yes_no_variants(s) : s }
      end
      @allowed_clamp_app_arguments.flatten!

      last_was_accepted = false
      ARGV.select { |arg| last_was_accepted = is_allowed_attribute_name?(arg) || (last_was_accepted && is_value?(arg)) }
    end

    def is_yes_no_flag?(s)
      s.include?('[no-]')
    end

    def build_yes_no_variants(s)
      [ s.sub('[no-]', ''), s.sub('[no-]', 'no-') ]
    end

    def is_allowed_attribute_name?(str)
      str =~ /([a-zA-Z0-9_-]*)([= ].*)?/ && @allowed_clamp_app_arguments.include?($1)
    end

    def is_value?(str)
      !str.start_with?('-')
    end

    def parse_app_arguments
      self.class.app_options.each do |option|
        name                    = option.attribute_name
        value                   = send(option.flag? ? "#{name}?" : name)

        if config.app.key?(name.to_sym)
          if !value.nil?
            config.app[name.to_sym] = value
          end
        else
          config.app[name.to_sym] = value.nil? ? option.default_value : value
        end
      end
    end

    def parse_cli_arguments
      # enable/disable modules according to CLI
      config.modules.each { |mod| send("enable_#{mod.name}?") ? mod.enable : mod.disable }

      # set and reset values coming from CLI arguments
      params.each do |param|
        if send("reset_#{u(with_prefix(param))}?")
          param.unset_value
        end
        variable_name = u(with_prefix(param))
        variable_name += '_list' if param.multivalued?
        cli_value     = instance_variable_get("@#{variable_name}")
        if argument_missing?(cli_value)
          puts "Parameter #{with_prefix(param)} is missing a value on the command line"
          self.class.exit(:missing_argument)
        end
        param.value   = cli_value unless cli_value.nil?
      end
    end

    def argument_missing?(value)
      !!self.class.declared_options.find { |opt| opt.handles?(value) }
    end

    def store_params(file = nil)
      data = Hash[config.modules.map { |mod| [mod.identifier, mod.enabled? ? mod.params_hash : false] }]
      config.store(data, file)
    end

    def validate_all(logging = true)
      logger.notice 'Running validation checks'
      results = enabled_params.map do |param|
        result = param.valid?
        errors = param.validation_errors.join(', ')
        progress_log(:error, "Parameter #{with_prefix(param)} invalid: #{errors}", logger) if logging && !result
        result
      end
      results.all?
    end

    def run_installation
      self.class.hooking.execute(:pre)

      execution_env = ExecutionEnvironment.new(config)
      self.class.exit_handler.register_cleanup_path(execution_env.directory)

      execution_env.store_answers
      puppetconf = execution_env.configure_puppet(
        'color'     => false,
        'evaltrace' => !!@progress_bar,
        'noop'      => !!noop?,
        'profile'   => !!profile?,
        'show_diff' => true,
      )

      exit_code   = 0
      exit_status = nil
      options     = [
          '--verbose',
          '--debug',
          '--detailed-exitcodes',
      ]
      begin
        command = PuppetCommand.new('include kafo_configure', options, puppetconf).command
        log_parser = PuppetLogParser.new
        logger = Logger.new('configure')
        logger.notice("Starting system configuration")

        PTY.spawn(*PuppetCommand.format_command(command)) do |stdin, stdout, pid|
          begin
            stdin.each do |line|
              line = normalize_encoding(line)
              method, message = log_parser.parse(line)
              progress_log(method, message, logger)
              @progress_bar.update(line) if @progress_bar
            end
          rescue Errno::EIO # we reach end of input
            exit_status = PTY.check(pid, true) if PTY.respond_to?(:check) # ruby >= 1.9.2
            if exit_status.nil? # process is still running or we have old ruby so we don't know
              begin
                Process.wait(pid)
              rescue Errno::ECHILD # process could exit meanwhile so we rescue
              end
              exit_code = $?.exitstatus
            end
          end
        end
      rescue PTY::ChildExited => e # could be raised by Process.wait on older ruby or by PTY.check
        exit_code = e.status.exitstatus
      end

      @progress_bar.close if @progress_bar
      logger.notice "Puppet has finished, bye!"

      self.class.exit(exit_code) do
        self.class.hooking.execute(:post)
      end
    end

    def progress_log(method, message, logger)
      @progress_bar.print_error(message + "\n") if method == :error && @progress_bar
      logger.send(method, message)
    end

    def unset
      params.select { |p| p.module.enabled? && p.value_set.nil? }
    end

    def config_file
      return CONFIG_FILE if defined?(CONFIG_FILE) && File.exists?(CONFIG_FILE)
      return self.class.scenario_manager.select_scenario if self.class.scenario_manager.configured?
      return '/etc/kafo/kafo.yaml' if File.exists?('/etc/kafo/kafo.yaml')
      return "#{::RbConfig::CONFIG['sysconfdir']}/kafo/kafo.yaml" if File.exists?("#{::RbConfig::CONFIG['sysconfdir']}/kafo/kafo.yaml")
      File.join(Dir.pwd, 'config', 'kafo.yaml')
    end

    def self.use_colors?
      if config
        colors = config.app[:colors]
      else
        colors = ARGV.include?('--no-colors') ? false : nil
        colors = ARGV.include?('--colors') ? true : nil if colors.nil?
      end
      colors
    end

    def self.preset_color_scheme
      match = ARGV.join(' ').match(/--color-of-background[ =](\w+)/)
      background = match && match[1]
      ColorScheme.new(:background => background, :colors => use_colors?).setup
    end

    def self.set_color_scheme
      ColorScheme.new(
        :background => config.app[:color_of_background],
        :colors => use_colors?).setup
    end

    private

    def normalize_encoding(line)
      if line.respond_to?(:encode) && line.respond_to?(:valid_encoding?)
        line.valid_encoding? ? line : line.encode('UTF-16be', :invalid => :replace, :replace => '?').encode('UTF-8')
      else  # Ruby 1.8.7, doesn't worry about invalid encodings
        line
      end
    end
  end
end
