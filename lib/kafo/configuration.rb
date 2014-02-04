# encoding: UTF-8
require 'yaml'
require 'kafo/puppet_module'
require 'kafo/password_manager'

module Kafo
  class Configuration
    attr_reader :config_file, :answer_file

    def self.colors_possible?
      !`which tput 2> /dev/null`.empty? && `tput colors`.to_i > 0
    end

    def self.answers_file
      defined?(::ANSWERS_FILE) ? ::ANSWERS_FILE : '/etc/kafo/answers.yaml'
    end

    DEFAULT = {
        :log_dir            => '/var/log/kafo',
        :log_name           => 'configuration.log',
        :log_level          => 'info',
        :no_prefix          => false,
        :mapping            => {},
        :answer_file        => Configuration.answers_file,
        :installer_dir      => '.',
        :modules_dir        => './modules',
        :default_values_dir => '/tmp',
        :colors             => Configuration.colors_possible?
    }

    def initialize(file, persist = true)
      @config_file = file
      @persist     = persist
      configure_application
      @logger = KafoConfigure.logger

      @answer_file = app[:answer_file]
      begin
        @data = YAML.load_file(@answer_file)
      rescue Errno::ENOENT => e
        puts "No answers file at #{@answer_file} found, can not continue"
        KafoConfigure.exit(:no_answer_file)
      end

      @config_dir = File.dirname(@config_file)
    end

    def save_configuration(configuration)
      return true unless @persist
      FileUtils.touch @config_file
      File.chmod 0600, @config_file
      File.open(@config_file, 'w') { |file| file.write(format(YAML.dump(configuration))) }
    end

    def configure_application
      result = app
      save_configuration(result)
      result
    end

    def app
      @app ||= begin
        begin
          configuration = YAML.load_file(@config_file)
        rescue => e
          configuration = {}
        end

        result            = DEFAULT.merge(configuration || {})
        result[:password] ||= PasswordManager.new.password
        result
      end
    end

    def modules
      @modules ||= @data.keys.map { |mod| PuppetModule.new(mod).parse }
    end

    def params_default_values
      @params_default_values ||= begin
        @logger.info "Parsing default values from puppet modules..."
        command = PuppetCommand.new("#{includes} dump_values(#{params})").append('2>&1').command
        @logger.debug `#{command}`
        unless $?.exitstatus == 0
          log = app[:log_dir] + '/' + app[:log_name]
          puts "Could not get default values, check log file at #{log} for more information"
          @logger.error "Could not get default values, cannot continue"
          KafoConfigure.exit(:defaults_error)
        end
        @logger.info "... finished"
        YAML.load_file(File.join(KafoConfigure.config.app[:default_values_dir], 'default_values.yaml'))
      end
    end

    # if a value is a true we return empty hash because we have no specific options for a
    # particular puppet module
    def [](key)
      value = @data[key]
      value.is_a?(Hash) ? value : {}
    end

    def module_enabled?(mod)
      value = @data[mod.is_a?(String) ? mod : mod.identifier]
      !!value || value.is_a?(Hash)
    end

    def config_header
      files          = [app[:config_header_file], File.join(KafoConfigure.gem_root, '/config/config_header.txt')].compact
      file           = files.select { |f| File.exists?(f) }.first
      @config_header ||= file.nil? ? '' : File.read(file)
    end

    def store(data, file = nil)
      filename = file || answer_file
      FileUtils.touch filename
      File.chmod 0600, filename
      File.open(filename, 'w') { |file| file.write(config_header + format(YAML.dump(data))) }
    end

    private

    def includes
      modules.map { |mod| "include #{mod.dir_name}::params" }.join(' ')
    end

    def params
      params = modules.map(&:params).flatten
      params = params.select { |p| p.default != 'UNSET' }
      params.map { |param| "#{param.dump_default}" }.join(',')
    end

    def format(data)
      data.gsub('!ruby/sym ', ':')
    end
  end
end
