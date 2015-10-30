# encoding: UTF-8
require 'kafo/param'
require 'kafo/param_builder'
require 'kafo_parsers/puppet_module_parser'
require 'kafo/validator'

module Kafo
  class PuppetModule
    PRIMARY_GROUP_NAME = 'Parameters'

    attr_reader :name, :identifier, :params, :dir_name, :class_name, :manifest_name, :manifest_path,
                :groups, :params_path, :params_class_name

    def initialize(identifier, parser = KafoParsers::PuppetModuleParser)
      @identifier        = identifier
      @name              = get_name
      @dir_name          = get_dir_name
      @manifest_name     = get_manifest_name
      @class_name        = get_class_name
      @params            = []
      if KafoConfigure.module_dirs.count == 1
        module_dir       = KafoConfigure.module_dirs.first
      else
        module_dir         = KafoConfigure.module_dirs.find { |dir| File.exists?(File.join(dir, module_manifest_path)) } ||
          warn("Manifest #{module_manifest_path} was not found in #{KafoConfigure.module_dirs.join(', ')}")
      end
      @manifest_path     = File.join(module_dir, module_manifest_path)
      @parser            = parser
      @validations       = []
      @logger            = KafoConfigure.logger
      @groups            = {}
      @params_path       = get_params_path
      @params_class_name = get_params_class_name
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
      @validations = raw_data[:validations]

      builder.validate
      @params = builder.build_params
      @groups = builder.build_param_groups(@params)

      self
    rescue ConfigurationException => e
      @logger.fatal "Unable to continue because of: #{e.message}"
      KafoConfigure.exit(:manifest_error)
    end

    def primary_parameter_group
      @groups.detect { |g| g.formatted_name == PRIMARY_GROUP_NAME } || dummy_primary_group
    end

    def other_parameter_groups
      @groups.select { |g| g.formatted_name != PRIMARY_GROUP_NAME }
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

    def <=> o
      KafoConfigure.config.app[:low_priority_modules].each do |module_name|
        return 1 if self.name.include?(module_name) && !o.name.include?(module_name)
        return -1 if !self.name.include?(module_name) && o.name.include?(module_name)
        if self.name.include?(module_name) && o.name.include?(module_name)
          return self.name.sub(/.*#{module_name}/, '') <=> o.name.sub(/.*#{module_name}/, '')
        end
      end

      self.name <=> o.name
    end

    private

    # used when user haven't specified any primary group by name, we create a new group
    # that holds all other groups as children, if we have no other groups (no children)
    # we set all parameters that this module hold
    def dummy_primary_group
      group = ParamGroup.new(PRIMARY_GROUP_NAME)
      other_parameter_groups.each { |child| group.add_child(child) }
      @params.each { |p| group.add_param(p) } if group.children.empty?
      group
    end

    # mapping from configuration with stringified keys
    def mapping
      @mapping ||= Hash[KafoConfigure.config.app[:mapping].map { |k, v| [k.to_s, v] }]
    end

    # custom module directory name
    def get_dir_name
      mapping[identifier].nil? ? name : mapping[identifier][:dir_name]
    end

    # custom manifest filename without .pp extension
    def get_manifest_name
      mapping[identifier].nil? ? 'init' : mapping[identifier][:manifest_name]
    end

    def get_class_name
      manifest_name == 'init' ? name : "#{dir_name}::#{manifest_name.gsub('/', '::')}"
    end

    def get_params_path
      mapping[identifier].nil? ? default_params_path : (mapping[identifier][:params_path] || default_params_path)
    end

    def get_params_name
      default = 'params'
      mapping[identifier].nil? ? default : (mapping[identifier][:params_name] || default)
    end

    def get_params_class_name
      name_to_class_name(get_params_name)
    end

    def module_manifest_path
      "#{dir_name}/manifests/#{manifest_name}.pp"
    end

    def default_params_path
      "#{dir_name}/manifests/#{get_params_name}.pp"
    end

    def get_name
      identifier.gsub('::', '_')
    end

    def name_to_class_name(name)
      name.gsub('/', '::')
    end

  end
end
