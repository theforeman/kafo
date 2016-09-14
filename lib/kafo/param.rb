# encoding: UTF-8
require 'kafo/condition'
require 'kafo/validator'
require 'kafo/data_type'

module Kafo
  class Param
    attr_reader :name, :module, :type
    attr_accessor :default, :doc, :value_set, :condition
    attr_writer :groups

    def initialize(builder, name, type)
      @name   = name
      @module = builder
      @type   = DataType.new_from_string(type)
    end

    def groups
      @groups || []
    end

    # we use @value_set flag because even nil can be valid value
    def value
      @value_set ? @type.typecast(@value) : default
    end

    def value=(value)
      @value_set = true
      value      = value.to_s if value.is_a?(::HighLine::String)  # don't persist highline extensions
      @value     = value
    end

    def unset_value
      @value_set = false
      @value     = nil
    end

    def dump_default
      @type.dump_default(default)
    end

    def module_name
      self.module.name
    end

    def to_s
      "#<#{self.class}:#{self.object_id} @name=#{name.inspect} @default=#{default.inspect} @value=#{value.inspect} @type=#{@type}>"
    end

    def set_default(defaults)
      if default == 'UNSET'
        self.default = nil
      else
        # if we don't have default value from dump (can happen for modules added from hooks,
        # or without using a params class), the existing default value from the manifest will
        # be used. On calling #value, the default will be returned if no overriding value is set.
        value = defaults.has_key?(default) ? defaults[default] : default
        case value
          when :undef
            # value can be set to :undef if value is not defined
            # (e.g. puppetmaster = $::puppetmaster which is not defined yet)
            self.default = nil
          when :undefined
            # in puppet 2.7 :undefined means that it's param which value is
            # not set by another parameter (e.g. foreman_group = 'something')
            # which means, default is sensible unlike dumped default
            # newer puppet has default dump in format 'value' => 'value' so
            # it's handled correctly by else branch
          else
            self.default = value
        end
      end
    end

    def set_value_by_config(config)
      base       = config[self.module.class_name]
      self.value = base[name] if base.has_key?(name)
    end

    def valid?
      # we get validations that can also run on other arguments, we need to take only current param
      # also we want to clone validations so we don't interfere
      validations = self.module.validations(self).map do |v|
        # These functions do not take more variables as arguments, instead we need to pass all arguments
        if v.name == 'validate_re' || v.name == 'validate_integer'
          args = v.arguments.to_a
        else
          args = v.arguments.select { |a| a.to_s == "$#{self.name}" }
        end
        {:name => v.name, :arguments => interpret_validation_args(args)}
      end

      # run old style validation functions
      @validator = Validator.new
      validations.each { |v| @validator.send(v[:name], v[:arguments]) }
      @validation_errors = @validator.errors.dup

      # run data type based validations, append errors
      @type.valid?(value, @validation_errors)

      @validation_errors.empty?
    end

    def validation_errors
      @validation_errors || []
    end

    def multivalued?
      @type.multivalued?
    end

    def <=> o
      unless @module.configuration.app[:no_prefix]
        r = self.module_name <=> o.module_name
        return r unless r == 0
      end
      self.name <=> o.name
    end

    def visible?(context = [])
      condition.nil? || condition.empty? ? true : evaluate_condition(context)
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
        arg == :undef ? nil : arg
      end
    end
  end
end

require 'kafo/params/password'
