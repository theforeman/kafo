# encoding: UTF-8
require 'kafo/condition'
require 'kafo/data_type'

module Kafo
  class Param
    UNSET_VALUES = ['UNSET', :undef]

    attr_reader :name, :module, :type, :manifest_default
    attr_accessor :doc, :value_set, :condition
    attr_writer :groups

    def initialize(builder, name, type)
      @name   = name
      @module = builder
      @type   = DataType.new_from_string(type)
      @default = nil
      @value_set = false
      @groups = nil
      @validation_errors = []
    end

    def identifier
      @module ? "#{@module.identifier}::#{name}" : name
    end

    def groups
      @groups || []
    end

    # we use @value_set flag because even nil can be valid value
    # Order of descending precedence: @value, @default (from dump), @manifest_default
    def value
      @value_set ? @type.typecast(@value) : default
    end

    def value=(value)
      @value_set = true
      @value     = normalize_value(value)
    end

    def unset_value
      @value_set = false
      @value     = nil
    end

    # For literal default values, only use 'manifest_default'. For variable or values from a data
    # lookup, use the value loaded back from the dump in 'default'.
    def default
      @type.typecast((dump_default_needed? || !@default.nil?) ? @default : manifest_default)
    end

    def default=(default)
      default = nil if UNSET_VALUES.include?(default)
      @default = default
    end

    # manifest_default may be a variable ($foo::params::bar) and need dumping from Puppet to get
    # the actual default value
    def dump_default_needed?
      manifest_default.to_s.start_with?('$')
    end

    def dump_default
      @type.dump_default(manifest_default_params_variable)
    end

    def manifest_default=(default)
      default = nil if UNSET_VALUES.include?(default)
      @manifest_default = default
    end

    def manifest_default_params_variable
      manifest_default[1..-1] if dump_default_needed?
    end

    def module_name
      self.module.name
    end

    def to_s
      "#<#{self.class}:#{self.object_id} @name=#{name.inspect} @default=#{default.inspect} @value=#{value.inspect} @type=#{@type}>"
    end

    def default_to_s
      internal_value_to_s(default)
    end

    def value_to_s
      internal_value_to_s(value)
    end

    def set_default_from_dump(defaults)
      # if we don't have default value from dump (can happen for modules added from hooks,
      # or without using a params class), the existing default value from the manifest will
      # be used. On calling #value, the default will be returned if no overriding value is set.
      if dump_default_needed? && defaults.has_key?(manifest_default_params_variable)
        self.default = defaults[manifest_default_params_variable]
      elsif defaults.has_key?(identifier)
        self.default = defaults[identifier]
      end
    end

    def set_value_by_config(config)
      base       = config[self.module.class_name]
      self.value = base[name] if base.has_key?(name)
    end

    def valid?
      @validation_errors = []

      # run data type based validations, append errors
      @type.valid?(value, @validation_errors)

      @validation_errors.empty?
    end

    def validation_errors
      @validation_errors
    end

    def multivalued?
      @type.multivalued?
    end

    def <=>(other)
      unless @module.configuration.app[:no_prefix]
        r = self.module_name <=> other.module_name
        return r unless r == 0
      end
      self.name <=> other.name
    end

    def visible?(context = [])
      (condition.nil? || condition.empty?) ? true : evaluate_condition(context)
    end

    def condition_value
      @type.condition_value(value)
    end

    private

    def evaluate_condition(context = [])
      Condition.new(condition, context).evaluate
    end

    def interpret_validation_args(args)
      args.map do |arg|
        if arg.to_s == "$#{self.name}"
          self.value
        elsif arg.is_a? String
          arg.gsub("$#{self.name}", self.value.to_s)
        else
          arg
        end
      end.map do |arg|
        (arg == :undef) ? nil : arg
      end
    end

    def normalize_value(value)
      case value
        when ::HighLine::String  # don't persist highline extensions
          value.to_s
        when Array
          value.map { |v| normalize_value(v) }
        when Hash
          Hash[value.map { |k,v| [normalize_value(k), normalize_value(v)] }]
        else
          value
      end
    end

    def internal_value_to_s(value)
      value.nil? ? 'UNDEF' : value.inspect
    end
  end
end
