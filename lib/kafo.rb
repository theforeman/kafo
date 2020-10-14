# encoding: UTF-8

require 'kafo/version'

# First of all we have to store ENV variable, requiring facter can override them
module Kafo
  module ENV
    LANG = ::ENV['LANG']
  end

  autoload :BaseContext, 'kafo/base_context'
  autoload :ColorScheme, 'kafo/color_scheme'
  autoload :Condition, 'kafo/condition'
  autoload :ConditionError, 'kafo/exceptions'
  autoload :Configuration, 'kafo/configuration'
  autoload :ConfigurationException, 'kafo/exceptions'
  autoload :DataType, 'kafo/data_type'
  autoload :DataTypeParser, 'kafo/data_type_parser'
  autoload :DataTypes, 'kafo/data_type' # This is inconsistent
  autoload :ExecutionEnvironment, 'kafo/execution_environment'
  autoload :ExitHandler, 'kafo/exit_handler'
  autoload :FactWriter, 'kafo/fact_writer'
  autoload :HelpBuilders, 'kafo/help_builders'
  autoload :HieraConfigurer, 'kafo/hiera_configurer'
  autoload :HookContext, 'kafo/hook_context'
  autoload :Hooking, 'kafo/hooking'
  autoload :KafoConfigure, 'kafo/kafo_configure'
  autoload :Logger, 'kafo/logger'
  autoload :Logging, 'kafo/logging'
  autoload :MigrationContext, 'kafo/migration_context'
  autoload :Migrations, 'kafo/migrations'
  autoload :Param, 'kafo/param'
  autoload :ParamBuilder, 'kafo/param_builder'
  autoload :ParamGroup, 'kafo/param_group'
  autoload :ParserCacheReader, 'kafo/parser_cache_reader'
  autoload :ParserCacheWriter, 'kafo/parser_cache_writer'
  autoload :ParserError, 'kafo/exceptions'
  autoload :ProgressBar, 'kafo/progress_bar'
  autoload :ProgressBars, 'kafo/progress_bars'
  autoload :PuppetCommand, 'kafo/puppet_command'
  autoload :PuppetConfigurer, 'kafo/puppet_configurer'
  autoload :PuppetLogParser, 'kafo/puppet_log_parser'
  autoload :PuppetModule, 'kafo/puppet_module'
  autoload :ScenarioManager, 'kafo/scenario_manager'
  autoload :Store, 'kafo/store'
  autoload :StringHelper, 'kafo/string_helper'
  autoload :SystemChecker, 'kafo/system_checker'
  autoload :TypeError, 'kafo/exceptions'
  autoload :Wizard, 'kafo/wizard'
end
