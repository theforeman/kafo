require 'pty'
require 'clamp'
require 'kafo/exceptions'
require 'kafo/configuration'
require 'kafo/logger'
require 'kafo/string_helper'
require 'kafo/wizard'
require 'kafo/system_checker'

class KafoConfigure < Clamp::Command
  include StringHelper
  attr_reader :logger

  class << self
    attr_accessor :config, :root_dir
  end

  def initialize(*args)
    root_dir            = Dir.pwd
    @logger             = Logging.logger.root
    # TODO read also file from different places (aka foreman_install puppet)
    config_file         = File.join(root_dir, 'config', 'answers.yaml')
    self.class.config   = Configuration.new(config_file)
    self.class.root_dir = root_dir
    set_env
    super
    set_parameters
    set_options
  end

  def config
    self.class.config
  end

  def execute
    parse_cli_arguments

    if verbose?
      logger.appenders = logger.appenders << ::Logging.appenders.stdout(:layout => COLOR_LAYOUT)
    end

    unless SystemChecker.check
      puts "Your system does not meet configuration criteria"
      exit(20)
    end

    if interactive?
      wizard = Wizard.new
      wizard.run
    else
      unless validate_all
        puts "Error during configuration, exiting"
        exit(21)
      end
    end

    store_params unless dont_save_answers?
    run_installation
  end

  private

  def params
    @params ||= config.modules.map(&:params).flatten
  rescue ModuleName => e
    puts e
    exit(24)
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
                      :default => false

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

  def store_params
    data = Hash[config.modules.map { |mod| [mod.name, mod.enabled? ? mod.params_hash : false] }]
    config.store(data)
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
    modules_path = "modules:#{File.join(File.dirname(__FILE__), '../../modules')}"
    options = [
        "--modulepath #{modules_path}",
        '--verbose',
        '--debug',
        '--color=false',
        '--show_diff',
        '--detailed-exitcodes',
    ]
    options.push '--noop' if noop?
    begin
      PTY.spawn("echo 'include kafo_configure' | puppet apply #{options.join(' ')}") do |stdin, stdout, pid|
        begin
          stdin.each { |line| puppet_log(line) }
        rescue Errno::EIO
          exit_code = PTY.check(pid).exitstatus
        end
      end
    rescue PTY::ChildExited
    end
    logger.info "Puppet has finished, bye!"
    exit(exit_code)
  end

  def puppet_log(line)
    method, message = case
                        when line =~ /^Error:(.*)/i
                          [:error, $1]
                        when line =~ /^Warning:(.*)/i
                          [:warn, $1]
                        when line =~ /^Notice:(.*)/i
                          [:warn, $1]
                        when line =~ /^Info:(.*)/i
                          [:info, $1]
                        when line =~ /^Debug:(.*)/i
                          [:debug, $1]
                        else
                          [:info, line]
                      end
    Logging.logger['puppet'].send(method, message.chomp)
  end

  def unset
    params.select { |p| p.module.enabled? && p.value_set.nil? }
  end

  def set_env
    # Puppet tries to determine FQDN from /etc/resolv.conf and we do NOT want this behavior
    facter_hostname = Socket.gethostname
    ENV['FACTER_fqdn'] = facter_hostname
  end

end
