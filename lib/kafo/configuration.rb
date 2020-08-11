# encoding: UTF-8
require 'yaml'
require 'tmpdir'
require 'kafo/puppet_module'
require 'kafo/color_scheme'
require 'kafo/data_type_parser'
require 'kafo/execution_environment'

module Kafo
  class Configuration
    attr_reader :config_file, :answer_file, :scenario_id

    DEFAULT = {
        :name                 => '',
        :description          => '',
        :enabled              => true,
        :log_dir              => '/var/log/kafo',
        :store_dir            => '',
        :log_name             => 'configuration.log',
        :log_level            => 'info',
        :no_prefix            => false,
        :mapping              => {},
        :answer_file          => './config/answers.yaml',
        :installer_dir        => '.',
        :module_dirs          => ['./modules'],
        :colors               => Kafo::ColorScheme.colors_possible?,
        :color_of_background  => :dark,
        :hook_dirs            => [],
        :custom               => {},
        :facts                => {},
        :low_priority_modules => [],
        :verbose_log_level    => 'info',
        :skip_puppet_version_check => false
    }

    def self.get_scenario_id(filename)
      File.basename(filename, '.yaml')
    end

    def initialize(file, persist = true)
      @config_file = file
      @persist     = persist
      configure_application
      @logger = KafoConfigure.logger

      @answer_file = app[:answer_file]
      begin
        @data = load_yaml_file(@answer_file)
      rescue Errno::ENOENT
        puts "No answer file at #{@answer_file} found, can not continue"
        KafoConfigure.exit(:no_answer_file)
      end

      @config_dir = File.dirname(@config_file)
      @scenario_id = Configuration.get_scenario_id(@config_file)
    end

    def save_configuration(configuration)
      return true unless @persist
      begin
        FileUtils.touch @config_file
        File.chmod 0600, @config_file
        File.open(@config_file, 'w') { |file| file.write(format(YAML.dump(configuration))) }
      rescue Errno::EACCES
        puts "Insufficient permissions to write to #{@config_file}, can not continue"
        KafoConfigure.exit(:insufficient_permissions)
      end
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
        rescue
          configuration = {}
        end

        result            = DEFAULT.merge(configuration || {})
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

    def get_custom_fact(key)
      custom_fact_storage[key.to_s]
    end

    def set_custom_fact(key, value)
      custom_fact_storage[key.to_s] = value
    end

    def has_custom_fact?(key)
      custom_fact_storage.key?(key.to_s)
    end

    def modules
      @modules ||= begin
        register_data_types
        @data.keys.map { |mod| PuppetModule.new(mod, PuppetModule.find_parser, self).parse }.sort
      end
    end

    def module(name)
      modules.find { |m| m.name == name }
    end

    def root_dir
      File.expand_path(app[:installer_dir])
    end

    def check_dirs
      [app[:check_dirs] || File.join(root_dir, 'checks')].flatten
    end

    def module_dirs
      [app[:module_dirs] || (app[:installer_dir] + '/modules')].flatten.map { |dir| File.expand_path(dir) }.uniq
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
      keys = [:log_dir, :log_name, :log_level, :no_prefix,
        :colors, :color_of_background, :custom, :verbose_log_level]
      keys += options.fetch(:with, [])
      keys.each do |key|
        next if keys_to_skip.include?(key)
        app[key] = from_config.app[key]
      end
      save_configuration(app)
    end

    def params_default_values
      @params_default_values ||= begin
        execution_env = ExecutionEnvironment.new(self)
        KafoConfigure.exit_handler.register_cleanup_path(execution_env.directory)

        puppetconf = execution_env.configure_puppet('noop' => true)

        dump_manifest = <<EOS
          #{includes}
          class { '::kafo_configure::dump_values':
            lookups   => [#{param_lookups_to_dump}],
            variables => [#{params_to_dump}],
          }
EOS

        ::Logging.mdc['stage'] = 'defaults'
        @logger.info 'Loading default values from puppet modules...'
        command = PuppetCommand.new(dump_manifest, [], puppetconf, self).command
        stdout, stderr, status = Open3.capture3(*PuppetCommand.format_command(command))

        @logger.debug stdout
        @logger.debug stderr

        unless status.success?
          log = app[:log_dir] + '/' + app[:log_name]

          if (version_mismatch = /kafo_configure::puppet_version_failure: (.+?\))/.match(stderr))
            puts version_mismatch[1]
            puts "Cannot continue due to incompatible version of Puppet. Use --skip-puppet-version-check to disable this check."
            @logger.error version_mismatch[1]
            @logger.error 'Incompatible version of Puppet used, cannot continue'
            KafoConfigure.exit(:puppet_version_error)
          else
            puts "Could not get default values, check log file at #{log} for more information"
            @logger.error command
            @logger.error stderr
            @logger.error 'Could not get default values, cannot continue'
            KafoConfigure.exit(:defaults_error)
          end
        end

        @logger.info "... finished"
        ::Logging.mdc.delete('stage')

        load_yaml_from_output(stdout.split($/))
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
      file           = files.find { |f| File.exist?(f) }
      @config_header ||= file.nil? ? '' : File.read(file)
    end

    def store(data, file = nil)
      filename = file || answer_file
      FileUtils.touch filename
      File.chmod 0600, filename
      File.open(filename, 'w') { |f| f.write(config_header + format(YAML.dump(data))) }
    end

    def params
      @params ||= modules.map(&:params).flatten
    end

    def param(mod_name, param_name)
      mod = self.module(mod_name)
      mod.nil? ? nil : mod.params.find { |p| p.name == param_name }
    end

    def preset_defaults_from_puppet
      # set values based on default_values
      params.each do |param|
        param.set_default_from_dump(params_default_values)
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

    def log_file
      File.join(app[:log_dir], app[:log_name])
    end

    def log_files_pattern
      log_file.sub(/(\.log)\Z/i) { |suffix| "{.[0-9]*,}#{suffix}" }
    end

    def log_files
      Dir.glob(log_files_pattern)
    end

    def log_exists?
      log_files.any? { |f| File.size(f) > 0 }
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
        @parser_cache ||= Kafo::ParserCacheReader.new_from_file(app[:parser_cache_path])
      end
    end

    private

    def custom_storage
      app[:custom]
    end

    def custom_fact_storage
      app[:facts]
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
      params.select(&:dump_default_needed?).map(&:dump_default).join(',')
    end

    def param_lookups_to_dump
      params.select { |p| p.manifest_default.nil? }.map { |p| %{"#{p.identifier}"} }.join(',')
    end

    def format(data)
      data.gsub('!ruby/sym ', ':')
    end

    def load_yaml_file(filename)
      YAML.load_file(filename)
    end

    # Loads YAML from mixed output, finding the "---" and "..." document start/end delimiters
    def load_yaml_from_output(lines)
      start = lines.find_index { |l| l.start_with?('---') }
      last = lines[start..-1].find_index("...")
      if start.nil? || last.nil?
        puts "Could not find default values in output"
        @logger.error 'Could not find default values in Puppet output, cannot continue'
        KafoConfigure.exit(:defaults_error)
      end
      YAML.load(lines[start,last].join($/))
    end

    def register_data_types
      module_dirs.each do |module_dir|
        Dir[File.join(module_dir, '*', 'types', '**', '*.pp')].each do |type_file|
          DataTypeParser.new(File.read(type_file)).register
        end
      end
    end
  end
end
