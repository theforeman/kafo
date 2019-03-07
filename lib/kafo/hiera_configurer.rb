require 'fileutils'
require 'tmpdir'

module Kafo
  class HieraConfigurer
    HIERARCHY_NAME = 'Kafo Answers'
    HIERARCHY_FILENAME = 'kafo_answers.yaml'

    attr_reader :temp_dir, :config_path, :data_dir, :logger

    def initialize(user_config_path, modules, modules_order)
      @user_config_path = user_config_path
      @modules = modules
      @modules_order = modules_order
      @logger = KafoConfigure.logger
    end

    def write_configs
      build_temp_dir

      if @user_config_path
        logger.debug("Merging existing Hiera config file from #{@user_config_path}")
        user_config = YAML.load(File.read(@user_config_path))
      else
        user_config = {}
      end
      logger.debug("Writing Hiera config file to #{config_path}")
      File.open(config_path, 'w') do |f|
        # merge required config changes into the user's Hiera config
        f.write(format_yaml_symbols(generate_config(user_config).to_yaml))
      end

      logger.debug("Creating Hiera data files in #{data_dir}")
      FileUtils.mkdir(data_dir)

      File.open(File.join(data_dir, HIERARCHY_FILENAME), 'w') do |f|
        f.write(format_yaml_symbols(generate_data(@modules).to_yaml))
      end
    end

    def generate_config(config = {})
      config ||= {}

      config['version'] = 5

      # ensure there are defaults
      config['defaults'] ||= {}
      config['defaults']['datadir'] = determine_data_dir_path(config['defaults']['datadir'])
      config['defaults']['data_hash'] ||= 'yaml_data'

      # ensure our answers file is present and has the right settings
      config['hierarchy'] ||= []

      config['hierarchy'].each do |level|
        if level['datadir']
          level['datadir'] = determine_data_dir_path(level['datadir'])
        end
      end

      kafo_answers = config['hierarchy'].find { |level| level['name'] == HIERARCHY_NAME }
      if kafo_answers
        kafo_answers.clear
      else
        kafo_answers = {}
        config['hierarchy'].unshift(kafo_answers)
      end
      kafo_answers['name'] = HIERARCHY_NAME
      kafo_answers['path'] = HIERARCHY_FILENAME
      kafo_answers['datadir'] = data_dir
      kafo_answers['data_hash'] = 'yaml_data'

      config
    end

    def generate_data(modules)
      classes = []
      data = modules.select(&:enabled?).inject({}) do |config, mod|
        classes << mod.class_name
        config.update(Hash[mod.params_hash.map { |k, v| ["#{mod.class_name}::#{k}", v] }])
      end
      data['classes'] = @modules_order ? sort_modules(classes, @modules_order) : classes
      data
    end

    def sort_modules(modules, order)
      (order & modules) + (modules - order)
    end

    def build_temp_dir
      @temp_dir ||= Dir.mktmpdir('kafo_hiera')
      @config_path = File.join(temp_dir, 'hiera.conf')
      @data_dir = File.join(temp_dir, 'data')
    end

    private

    def format_yaml_symbols(data)
      data.gsub('!ruby/sym ', ':')
    end

    def determine_data_dir_path(path)
      # Relies on data_dir being absolute or having a user config
      path ||= data_dir
      Pathname.new(path).relative? ? File.join(original_hiera_directory, path) : path
    end

    def original_hiera_directory
      @user_config_path ? File.dirname(@user_config_path) : nil
    end
  end
end
