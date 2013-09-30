# encoding: UTF-8
require 'facter'
require 'pty'
require 'clamp'
require 'kafo/exceptions'
require 'kafo/configuration'
require 'kafo/logger'
require 'kafo/string_helper'
require 'kafo/wizard'
require 'kafo/system_checker'
require 'kafo/puppet_command'
require 'kafo/progress_bar'

class KafoConfigure < Clamp::Command
  include StringHelper
  attr_reader :logger

  class << self
    attr_accessor :config, :root_dir, :config_file, :gem_root, :temp_config_file,
                  :modules_dir, :kafo_modules_dir, :verbose
  end

  def initialize(*args)
    self.class.config_file = config_file
    self.class.config      = Configuration.new(self.class.config_file)
    self.class.root_dir    = File.expand_path(self.class.config.app[:installer_dir])
    modules_dir            = self.class.config.app[:module_dir] || (self.class.config.app[:installer_dir] + '/modules')
    self.class.modules_dir = File.expand_path(modules_dir)
    self.class.gem_root    = File.join(File.dirname(__FILE__), '../../')
    self.class.kafo_modules_dir = self.class.config.app[:kafo_modules_dir] || (self.class.gem_root + '/modules')
    Logger.setup
    @logger = Logging.logger.root
    @progress_bar = nil
    super
    set_parameters
    set_options
  end

  def config
    self.class.config
  end

  def execute
    catch :exit do
      parse_cli_arguments

      if (self.class.verbose = verbose?)
        logger.appenders = logger.appenders << ::Logging.appenders.stdout(:layout => Logger::COLOR_LAYOUT)
      else
        @progress_bar = ProgressBar.new
      end

      unless SystemChecker.check
        puts "Your system does not meet configuration criteria"
        exit(:invalid_system)
      end

      if interactive?
        wizard = Wizard.new
        wizard.run
      else
        unless validate_all
          puts "Error during configuration, exiting"
          exit(:invalid_values)
        end
      end

      if dont_save_answers?
        self.class.temp_config_file = temp_config_file
        store_params(temp_config_file)
      else
        store_params
      end
      run_installation
    end
    return self
  end

  def self.run
    catch :exit do
      return super
    end
    Kernel.exit(self.exit_code) # fail in initialize
  end

  def exit_code
    self.class.exit_code
  end

  def self.exit(code)
    @exit_code = translate_exit_code(code)
    throw :exit
  end

  def self.exit_code
    @exit_code ||= 0
  end

  def self.translate_exit_code(code)
    return code if code.is_a? Fixnum
    error_codes = { :invalid_system => 20,
                    :invalid_values => 21,
                    :manifest_error => 22,
                    :no_answer_file => 23,
                    :unknown_module => 24,
                    :defaults_error => 25}
    if error_codes.has_key? code
      return error_codes[code]
    else
      raise "Unknown code #{code}"
    end
  end

  def params
    @params ||= modules.map(&:params).flatten
  rescue ModuleName => e
    puts e
    exit(:unknown_module)
  end

  def modules
    config.modules
  end

  def module(name)
    modules.detect { |m| m.name == name}
  end

  def param(mod, name)
    params.detect { |p| p.name == name && p.module.name == mod }
  end

  private

  def exit(code)
    self.class.exit(code)
  end

  def set_parameters
    params.each do |param|
      # set values based on default_values
      param.set_default(config.params_default_values)
      # set values based on YAML
      param.set_value_by_config(config)
    end
  end

  def set_options
    self.class.option ['-i', '--interactive'], :flag, 'Run in interactive mode'
    self.class.option ['-v', '--verbose'], :flag, 'Display log on STDOUT instead of progressbar'
    self.class.option ['-n', '--noop'], :flag, 'Run puppet in noop mode?', :default => false
    self.class.option ['-d', '--dont-save-answers'], :flag, 'Skip saving answers to answers.yaml?',
                      :default => !!config.app[:dont_save_answers]

    config.modules.each do |mod|
      self.class.option d("--[no-]enable-#{mod.name}"),
                        :flag,
                        "Enable puppet module #{mod.name}?",
                        :default => mod.enabled?
    end

    params.each do |param|
      doc = param.doc.nil? ? 'UNDOCUMENTED' : param.doc.join("\n")
      self.class.option parametrize(param), '', doc,
                        :default => param.value, :multivalued => param.multivalued?
    end
  end

  def parse_cli_arguments
    # enable/disable modules according to CLI
    config.modules.each { |mod| send("enable_#{mod.name}?") ? mod.enable : mod.disable }

    # set values coming from CLI arguments
    params.each do |param|
      variable_name = u(with_prefix(param))
      variable_name += '_list' if param.multivalued?
      cli_value = instance_variable_get("@#{variable_name}")
      param.value = cli_value unless cli_value.nil?
    end
  end

  def store_params(file = nil)
    data = Hash[config.modules.map { |mod| [mod.name, mod.enabled? ? mod.params_hash : false] }]
    config.store(data, file)
  end

  def validate_all(logging = true)
    logger.info 'Running validation checks'
    results = params.map do |param|
      result = param.valid?
      logger.error "Parameter #{param.name} invalid" if logging && !result
      result
    end
    results.all?
  end

  def run_installation
    exit_code = 0
    options = [
        '--verbose',
        '--debug',
        '--color=false',
        '--show_diff',
        '--detailed-exitcodes',
    ]
    options.push '--noop' if noop?
    begin
      command = PuppetCommand.new('include kafo_configure', options).command
      PTY.spawn(command) do |stdin, stdout, pid|
        begin
          stdin.each do |line|
            puppet_log(*puppet_parse(line))
            @progress_bar.update(line) if @progress_bar
          end
        rescue Errno::EIO
          if PTY.respond_to?(:check) # ruby >= 1.9.2
            exit_code = PTY.check(pid, true).exitstatus
          else # ruby < 1.9.2
            Process.wait(pid) rescue Errno::ECHILD
            exit_code = $?.exitstatus
          end
        end
      end
    rescue PTY::ChildExited => e
      exit_code = e.status.exitstatus
    end
    @progress_bar.close if @progress_bar
    logger.info "Puppet has finished, bye!"
    FileUtils.rm(temp_config_file, :force => true)
    exit(exit_code)
  end

  def puppet_log(method, message)
    @progress_bar.print ANSI::Code.red { message + "\n" } if method == :error && @progress_bar
    Logging.logger['puppet'].send(method, message)
  end

  def puppet_parse(line)
    method, message = case
                        when line =~ /^Error:(.*)/i || line =~ /^Err:(.*)/i
                          [:error, $1]
                        when line =~ /^Warning:(.*)/i || line =~ /^Notice:(.*)/i
                          [:warn, $1]
                        when line =~ /^Info:(.*)/i
                          [:info, $1]
                        when line =~ /^Debug:(.*)/i
                          [:debug, $1]
                        else
                          [:info, line]
                      end

    return [method, message.chomp]
  end

  def unset
    params.select { |p| p.module.enabled? && p.value_set.nil? }
  end

  def config_file
    return CONFIG_FILE if defined?(CONFIG_FILE) && File.exists?(CONFIG_FILE)
    return '/etc/kafo/kafo.yaml' if File.exists?('/etc/kafo/kafo.yaml')
    File.join(Dir.pwd, 'config', 'kafo.yaml')
  end

  def temp_config_file
    @temp_config_file ||= "/tmp/kafo_answers_#{rand(1_000_000)}.yaml"
  end
end
