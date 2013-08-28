require 'yaml'
require 'kafo/puppet_module'
require 'kafo/password_manager'

class Configuration
  attr_reader :config_file

  def self.application_config_file
    File.join(Dir.pwd, 'config/kafo.yaml')
  end

  def self.save_configuration(configuration)
    File.open(application_config_file, 'w') { |file| file.write(YAML.dump(configuration)) }
  end

  def self.configure_application
    begin
      configuration = YAML.load_file(application_config_file)
    rescue => e
      configuration = {}
    end

    default           = {
      :log_dir   => '/var/log/kafo',
      :log_level => :info,
      :no_prefix => false,
      :mapping   => {}
    }
    
    result            = default.merge(configuration || {})
    result[:password] ||= PasswordManager.new.password
    save_configuration(result)

    result
  end

  KAFO = configure_application

  def initialize(file)
    @logger = Logging.logger.root
    @logger.info "Loading config file #{file}"

    begin
      @data        = YAML.load_file(file)
    rescue Errno::ENOENT => e
      puts "No answers file at #{file} found, can not continue"
      exit(23)
    end

    @config_file = file
    @config_dir  = File.join(Dir.pwd, 'config')
  end

  def modules
    @modules ||= @data.keys.map { |mod| PuppetModule.new(mod).parse }
  end

  def params_default_values
    @params_default_values ||= begin
      @logger.info "Parsing default values from puppet modules..."
      # TODO not dry, kafo_configure.rb does similar thing
      modules_path = "modules:#{File.join(gem_root_path, 'modules')}"
      @logger.debug `echo '#{includes} dump_values(#{params})' | puppet apply --modulepath #{modules_path} 2>&1`
      unless $?.exitstatus == 0
        @logger.error "Could not get default values, cannot continue"
        exit(25)
      end
      @logger.info "... finished"
      YAML.load_file(File.join(@config_dir, 'default_values.yaml'))
    end
  end

  # if a value is a true we return empty hash because we have no specific options for a
  # particular puppet module
  def [](key)
    value = @data[key]
    value.is_a?(Hash) ? value : {}
  end

  def module_enabled?(mod)
    value = @data[mod.name]
    !!value || value.is_a?(Hash)
  end

  def config_header
    @config_header ||= File.read(File.join(gem_root_path, '/config/config_header.txt'))
  end

  def gem_root_path
    @gem_root_path ||= File.join(File.dirname(__FILE__), '../../')
  end

  def store(data)
    File.open(config_file, 'w') { |file| file.write(config_header + YAML.dump(data)) }
  end

  private

  def includes
    modules.map { |mod| "include #{mod.dir_name}::params" }.join(' ')
  end

  def params
    params = modules.map(&:params).flatten
    params = params.select { |p| p.default != 'UNSET' }
    params.map { |param| "#{param.default}" }.join(',')
  end
end
