# encoding: UTF-8
require 'yaml'
require 'tmpdir'
require 'kafo/puppet_module'
require 'kafo/password_manager'
require 'kafo/color_scheme'

module Kafo
  class Configuration
    attr_reader :config_file, :answer_file

    DEFAULT = {
        :name                 => '',
        :description          => '',
        :enabled              => true,
        :log_dir              => '/var/log/kafo',
        :log_name             => 'configuration.log',
        :log_level            => 'info',
        :no_prefix            => false,
        :mapping              => {},
        :answer_file          => './config/answers.yaml',
        :installer_dir        => '.',
        :module_dirs          => ['./modules'],
        :default_values_dir   => '/tmp',
        :colors               => Kafo::ColorScheme.colors_possible?,
        :color_of_background  => :dark,
        :hook_dirs            => [],
        :custom               => {},
        :low_priority_modules => [],
        :verbose_log_level    => 'info'
    }

    def initialize(file, persist = true)
      @config_file = file
      @persist     = persist
      configure_application
      @logger = KafoConfigure.logger

      @answer_file = app[:answer_file]
      begin
        @data = load_yaml_file(@answer_file)
      rescue Errno::ENOENT => e
        puts "No answer file at #{@answer_file} found, can not continue"
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
          configuration = load_yaml_file(@config_file)
        rescue => e
          configuration = {}
        end

        result            = DEFAULT.merge(configuration || {})
        result[:password] ||= PasswordManager.new.password
        result[:module_dirs] = result[:modules_dir] || result[:module_dirs]
        result.delete(:modules_dir)
        result
      end
    end

    def get_custom(key)
      custom_storage[key.to_sym]
    end

    def set_custom(key, value)
      custom_storage[key.to_sym] = value
    end

    def modules
      @modules ||= @data.keys.map { |mod| PuppetModule.new(mod, PuppetModule.find_parser, self).parse }.sort
    end

    def root_dir
      File.expand_path(app[:installer_dir])
    end

    def check_dirs
      [app[:check_dirs] || File.join(root_dir, 'checks')].flatten
    end

    def module_dirs
      [app[:module_dirs] || (app[:installer_dir] + '/modules')].flatten.map { |dir| File.expand_path(dir) }
    end

    def gem_root
      File.join(File.dirname(__FILE__), '../../')
    end

    def kafo_modules_dir
      app[:kafo_modules_dir] || (gem_root + '/modules')
    end

    def add_module(name)
      mod = PuppetModule.new(name, PuppetModule.find_parser, self).parse
      unless modules.map(&:name).include?(mod.name)
        mod.enable
        @modules << mod
      end
    end

    def add_mapping(module_name, mapping)
      app[:mapping][module_name] = mapping
      save_configuration(app)
    end

    def migrate_configuration(from_config, options={})
      keys_to_skip = options.fetch(:skip, [])
      keys = [:log_dir, :log_name, :log_level, :no_prefix, :default_values_dir,
        :colors, :color_of_background, :custom, :password, :verbose_log_level]
      keys += options.fetch(:with, [])
      keys.each do |key|
        next if keys_to_skip.include?(key)
        app[key] = from_config.app[key]
      end
      save_configuration(app)
    end

    def params_default_values
      @params_default_values ||= begin
        @logger.debug "Creating tmp dir within #{app[:default_values_dir]}..."
        temp_dir = Dir.mktmpdir(nil, app[:default_values_dir])
        KafoConfigure.exit_handler.register_cleanup_path temp_dir
        @logger.info 'Loading default values from puppet modules...'
        command = PuppetCommand.new("$temp_dir=\"#{temp_dir}\" #{includes} dump_values(#{params_to_dump})", ['--noop', '--reports='], self).append('2>&1').command
        result = `#{command}`
        @logger.debug result
        unless $?.exitstatus == 0
          log = app[:log_dir] + '/' + app[:log_name]
          puts "Could not get default values, check log file at #{log} for more information"
          @logger.error command
          @logger.error result
          @logger.error 'Could not get default values, cannot continue'
          KafoConfigure.exit(:defaults_error)
        end
        @logger.info "... finished"
        load_yaml_file(File.join(temp_dir, 'default_values.yaml'))
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
      files          = [app[:config_header_file], File.join(gem_root, '/config/config_header.txt')].compact
      file           = files.select { |f| File.exists?(f) }.first
      @config_header ||= file.nil? ? '' : File.read(file)
    end

    def store(data, file = nil)
      filename = file || answer_file
      FileUtils.touch filename
      File.chmod 0600, filename
      File.open(filename, 'w') { |file| file.write(config_header + format(YAML.dump(data))) }
    end

    def params
      @params ||= modules.map(&:params).flatten
    end

    def param(mod, name)
      params.detect { |p| p.name == name && p.module.name == mod }
    end

    def preset_defaults_from_puppet
      # set values based on default_values
      params.each do |param|
        param.set_default(params_default_values)
      end
    end

    def preset_defaults_from_yaml
      # set values based on YAML
      params.each do |param|
        param.set_value_by_config(self)
      end
    end

    def preset_defaults_from_other_config(other_config)
      params_changed(other_config).each do |par|
        param(par.module.class_name, par.name).value = other_config.param(par.module.class_name, par.name).value
      end
    end

    def params_changed(old_config)
      # finds params that had different value in the old config
      params.select do |par|
        next unless par.module.enabled?
        old_param = old_config.param(par.module.class_name, par.name)
        old_param && old_param.value != par.value
      end
    end

    def params_missing(old_config)
      # finds params that are present but will be missing in the new config
      old_config.params.select do |par|
        next if !par.module.enabled? || !module_enabled?(par.module.name)
        param(par.module.class_name, par.name).nil?
      end
    end

    def temp_config_file
      @temp_config_file ||= "/tmp/kafo_answers_#{rand(1_000_000)}.yaml"
    end

    def log_file
      File.join(app[:log_dir], app[:log_name])
    end

    def log_exists?
      File.exists?(log_file) && File.size(log_file) > 0
    end

    def answers
      @data
    end

    def run_migrations
      migrations = Kafo::Migrations.new(migrations_dir)
      @app, @data = migrations.run(app, answers)
      if migrations.migrations.count > 0
        @modules = nil # force the lazy loaded modules to reload next time they are used
        save_configuration(app)
        store(answers)
        migrations.store_applied
        @logger.info("#{migrations.migrations.count} migration/s were applied. Updated configuration was saved.")
      end
      migrations.migrations.count
    end

    def migrations_dir
      @config_file.gsub(/\.yaml$/, '.migrations')
    end

    def parser_cache
      if app[:parser_cache_path]
        @parser_cache ||= Kafo::ParserCacheReader.new_from_file(File.expand_path(app[:parser_cache_path]))
      end
    end

    private

    def custom_storage
      app[:custom]
    end

    def includes
      modules.map do |mod|
        module_dir = module_dirs.find do |dir|
          params_file = File.join(dir, mod.params_path)
          @logger.debug "checking presence of #{params_file}"
          File.exist?(params_file)
        end
        module_dir ? "include #{mod.dir_name}::#{mod.params_class_name}" : nil
      end.uniq.compact.join(' ')
    end

    def params_to_dump
      parameters = params.select { |p| p.default != 'UNSET' }
      parameters.map { |param| "#{param.dump_default}" }.join(',')
    end

    def format(data)
      data.gsub('!ruby/sym ', ':')
    end

    def load_yaml_file(filename)
      YAML.load_file(filename)
    end
  end
end
