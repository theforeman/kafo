module Kafo
  class HookContext < BaseContext
    attr_reader :kafo, :logger

    def self.execute(kafo, logger, &hook)
      new(kafo, logger).instance_eval(&hook)
    end

    def initialize(kafo, logger)
      @kafo = kafo
      @logger = logger
    end

    # some of hooks won't print any message because logger is not yet configured
    # configuration of logger depends on application configration (log level etc.)
    # examples:
    #   logger.warn "this combindation of parameters is untested"
    def logger
      @logger
    end

    # if you want to add new app_option be sure to do as soon as possible (usually boot hook)
    # otherwise it may be too late (e.g. when displaying help)
    # examples:
    #   app_option '--log-level', 'LEVEL', 'Log level for log file output', :default => config.app[:log_level]:
    #   app_option ['-n', '--noop'], :flag, 'Run puppet in noop mode?', :default => false
    def app_option(*args)
      self.kafo.class.app_option(*args)
    end

    # Returns whether the given app option exists. This is useful when there's a conditional option that is
    # determined during boot; this helper can be used in later hooks to determine whether the option exists.
    def app_option?(option)
      self.kafo.config.app.key?(option.to_sym)
    end

    # examples:
    #   app_value(:log_level)
    # note the dash to underscore convention
    def app_value(option)
      self.kafo.config.app[option.to_sym]
    end

    # examples:
    #   param('foreman', 'interface').value = 'eth0'
    #   param('foreman', 'interface').value = app_option('bind_on_interface')
    def param(module_name, parameter_name)
      self.kafo.param(module_name, parameter_name)
    end

    # You can add custom modules not explicitly enabled in answer file. This is especially
    # useful if you want to add your plugin to existing installer. This module will become
    # part of answer file so it also preserves parameter values between runs. It also list
    # its options in help output. You can also specify mapping for this module as a second
    # parameter.
    # examples:
    #   add_module('my_module')
    #   add_module('foreman::plugin::staypuft', {:dir_name => 'foreman', :manifest_name => 'plugin/staypuft'})
    def add_module(module_name, mapping = nil)
      self.kafo.config.add_mapping(module_name, mapping) if mapping
      self.kafo.add_module(module_name)
    end

    # Check if a module is enabled in the current configuration.
    # examples:
    #   module_enabled?('example')
    def module_enabled?(module_name)
      mod = self.kafo.module(module_name)
      !mod.nil? && mod.enabled?
    end

    # Check if a module is present in the current configuration.
    # examples:
    #   module_present?('example')
    def module_present?(module_name)
      mod = self.kafo.module(module_name)
      !mod.nil?
    end

    # You can trigger installer exit by this method. You must specify exit code as a first
    # argument. You can also specify a symbol alias which is built-in (see exit_handler.rb
    # for more details).
    # examples:
    #   exit(0)
    #   exit(:manifest_error)
    def exit(code)
      self.kafo.class.exit(code)
    end

    # You can load a custom config value that has been saved using store_custom_config
    def get_custom_config(key)
      self.kafo.config.get_custom(key)
    end

    # You can save any value into kafo configuration file, this is useful if you need to
    # share a value between more hooks and persist the values for next run
    def store_custom_config(key, value)
      self.kafo.config.set_custom(key, value)
    end

    # Load a custom fact from the custom fact storage as saved by store_custom_fact
    def get_custom_fact(key)
      self.kafo.config.get_custom_fact(key)
    end

    # Store any custom fact. This will show up as kafo.scenario.custom.your_fact.
    # It is possible to use structures such as arrays and hashes besides the
    # obvious ones such as strings, integers, booleans.
    #
    # These facts can also be used in Hiera hierachy definitions.
    def store_custom_fact(key, value)
      self.kafo.config.set_custom_fact(key, value)
    end

    # Check whether a custom fact exists, regardless of whether or not it has a value.
    def has_custom_fact?(key)
      self.kafo.config.has_custom_fact?(key)
    end

    # Return the id of the current scenario
    def scenario_id
      self.kafo.config.scenario_id
    end

    # Return the path to the current scenario
    def scenario_path
      self.kafo.config.config_file
    end

    # Return the actual data in the current scenario
    def scenario_data
      self.kafo.config.app
    end
  end
end
