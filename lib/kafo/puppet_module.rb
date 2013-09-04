require 'kafo/param'
require 'kafo/param_builder'
require 'kafo/puppet_module_parser'
require 'kafo/validator'

class PuppetModule
  attr_reader :name, :params, :dir_name, :class_name, :manifest_name, :manifest_path

  def initialize(name, parser = PuppetModuleParser)
    @name          = name
    @dir_name      = get_dir_name
    @manifest_name = get_manifest_name
    @class_name    = get_class_name
    @params        = []
    @manifest_path = File.join(KafoConfigure.root_dir, '/modules/', module_manifest_path)
    @parser        = parser
    @validations   = []
    @logger        = Logging.logger.root
  end

  def enabled?
    @enabled.nil? ? @enabled = KafoConfigure.config.module_enabled?(self) : @enabled
  end

  def disable
    @enabled = false
  end

  def enable
    @enabled = true
  end

  def parse(builder_klass = ParamBuilder)
    @params      = []
    raw_data     = @parser.parse(manifest_path)
    builder      = builder_klass.new(self, raw_data)
    @validations = raw_data['validations']

    builder.validate
    @params      = builder.build_params

    self
  rescue ConfigurationException => e
    puts "Unable to continue because of:"
    puts e.message
    KafoConfigure.exit(:manifest_error)
  end

  def validations(param = nil)
    if param.nil?
      @validations
    else
      @validations.select do |validation|
        validation.arguments.map(&:to_s).include?("$#{param.name}")
      end
    end
  end

  def params_hash
    Hash[params.map { |param| [param.name, param.value] }]
  end

  private

  # mapping from configuration with stringified keys
  def mapping
    @mapping ||= Hash[KafoConfigure.config.app[:mapping].map { |k, v| [k.to_s, v] }]
  end

  # custom module directory name
  def get_dir_name
    mapping[name].nil? ? name : mapping[name][:dir_name]
  end

  # custom manifest filename without .pp extension
  def get_manifest_name
    mapping[name].nil? ? 'init' : mapping[name][:manifest_name]
  end

  def get_class_name
    manifest_name == 'init' ? name : "#{dir_name}::#{manifest_name}"
  end

  def module_manifest_path
    "#{dir_name}/manifests/#{manifest_name}.pp"
  end

end
