# encoding: UTF-8
require 'kafo/param'
require 'kafo/param_builder'
require 'kafo/parser_cache_reader'
require 'kafo_parsers/parsers'

module Kafo
  class PuppetModule
    PRIMARY_GROUP_NAME = 'Parameters'

    attr_reader :name, :identifier, :params, :dir_name, :class_name, :manifest_name, :manifest_path,
                :groups, :params_path, :params_class_name, :configuration, :raw_data

    def self.find_parser
      @parser ||= begin
        logger = KafoConfigure.logger
        parser = KafoParsers::Parsers.find_available(:logger => logger)
        if parser
          logger.debug "Using Puppet module parser #{parser}"
          parser
        else
          logger.debug "No available Puppet module parser found"
          :none  # prevent continually re-checking
        end
      end
    end

    def initialize(identifier, parser: nil, configuration: KafoConfigure.config)
      @identifier        = identifier
      @configuration     = configuration
      @name              = get_name
      @dir_name          = get_dir_name
      @manifest_name     = get_manifest_name
      @class_name        = get_class_name
      @params            = []
      if @configuration.module_dirs.count == 1
        module_dir       = @configuration.module_dirs.first
      else
        module_dir         = @configuration.module_dirs.find { |dir| File.exist?(File.join(dir, module_manifest_path)) } ||
          warn("Manifest #{module_manifest_path} was not found in #{@configuration.module_dirs.join(', ')}")
      end
      @manifest_path     = File.join(module_dir, module_manifest_path)
      @parser            = parser
      @parser_cache      = @configuration.parser_cache
      @logger            = KafoConfigure.logger
      @groups            = {}
      @params_path       = get_params_path
      @params_class_name = get_params_class_name
      @raw_data          = nil
      @enabled           = nil
    end

    def enabled?
      @enabled.nil? ? @enabled = @configuration.module_enabled?(self) : @enabled
    end

    def disable
      @enabled = false
    end

    def enable
      @enabled = true
    end

    def parse(builder_klass = ParamBuilder)
      @raw_data = @parser_cache.get(identifier, manifest_path) if @parser_cache
      if @raw_data.nil?
        @parser = self.class.find_parser if @parser.nil?
        if @parser.nil? || @parser == :none
          raise ParserError.new("No Puppet module parser is installed and no cache of the file #{manifest_path} is available. Please check debug logs and install optional dependencies for the parser.")
        else
          @raw_data = @parser.parse(manifest_path)
        end
      end

      builder      = builder_klass.new(self, @raw_data)

      builder.validate
      @params = builder.build_params
      @groups = builder.build_param_groups(@params)

      self
    rescue ConfigurationException => e
      @logger.fatal "Unable to parse #{manifest_path} because of: #{e.message}"
      KafoConfigure.exit(:manifest_error)
    end

    def primary_parameter_group
      @groups.detect { |g| g.formatted_name == PRIMARY_GROUP_NAME } || dummy_primary_group
    end

    def other_parameter_groups
      @groups.select { |g| g.formatted_name != PRIMARY_GROUP_NAME }
    end

    def params_hash
      Hash[params.map { |param| [param.name, param.value] }]
    end

    def <=>(other)
      @configuration.app[:low_priority_modules].each do |module_name|
        return 1 if self.name.include?(module_name) && !other.name.include?(module_name)
        return -1 if !self.name.include?(module_name) && other.name.include?(module_name)
        if self.name.include?(module_name) && other.name.include?(module_name)
          return self.name.sub(/.*#{module_name}/, '') <=> other.name.sub(/.*#{module_name}/, '')
        end
      end

      self.name <=> other.name
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
      @mapping ||= Hash[@configuration.app[:mapping].map { |k, v| [k.to_s, v] }]
    end

    # custom module directory name
    def get_dir_name
      mapping[identifier].nil? ? default_dir_name : (mapping[identifier][:dir_name] || default_dir_name)
    end

    # custom manifest filename without .pp extension
    def get_manifest_name
      mapping[identifier].nil? ? default_manifest_name : (mapping[identifier][:manifest_name] || default_manifest_name)
    end

    def get_class_name
      (manifest_name == 'init') ? name : "#{dir_name}::#{manifest_name.gsub('/', '::')}"
    end

    def get_params_path
      mapping[identifier].nil? ? default_params_path : (mapping[identifier][:params_path] || default_params_path)
    end

    def get_params_name
      mapping[identifier].nil? ? default_params_name : (mapping[identifier][:params_name] || default_params_name)
    end

    def get_params_class_name
      name_to_class_name(get_params_name)
    end

    def module_manifest_path
      "#{dir_name}/manifests/#{manifest_name}.pp"
    end

    def default_dir_name
      identifier.split('::').first
    end

    def default_params_path
      "#{dir_name}/manifests/#{class_to_name(get_params_name)}.pp"
    end

    def default_manifest_name
      identifier.include?('::') ? identifier.split('::')[1..-1].join('/') : 'init'
    end

    def default_params_name
      identifier.include?('::') ? (identifier.split('::')[1..-1] + ['params']).join('/') : 'params'
    end

    def get_name
      identifier.gsub('::', '_')
    end

    def name_to_class_name(name)
      name.gsub('/', '::')
    end

    def class_to_name(name)
      name.gsub('::', '/')
    end

  end
end
