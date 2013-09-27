# encoding: UTF-8
class Param
  attr_reader :name, :module
  attr_accessor :default, :doc, :value_set

  def initialize(builder, name)
    @name = name
    @module = builder
  end

  # we use @value_set flag because even nil can be valid value
  def value
    @value_set ? @value : default
  end

  def value=(value)
    @value_set = true
    @value = value == 'UNDEF' ? nil : value
  end

  def module_name
    self.module.name
  end

  def to_s
    "#<#{self.class}:#{self.object_id} @name=#{name.inspect} @default=#{default.inspect} @value=#{value.inspect}>"
  end

  def set_default(defaults)
    if default == 'UNSET'
      self.value = nil
    else
      self.value = (value = defaults[default]) == :undef ? nil : value
    end
  end

  def set_value_by_config(config)
    base = config[module_name]
    self.value = base[name] if base.has_key?(name)
  end

  def valid?
    validations = self.module.validations(self)
    # we get validations that can also run on other arguments, we need to take only current param
    # also we want to clone validations so we don't interfere
    validations.map! do |v|
      v = v.clone
      if v.name == 'validate_re'
        # validate_re does not take more variables as arguments, instead we need to pass all arguments
        args = v.arguments
      else
        args = v.arguments.select { |a| a.to_s == "$#{self.name}" }
      end
      v.arguments = Puppet::Parser::AST::ASTArray.new :children => args
      v
    end

    validator = Validator.new([self])
    validations.map! do |v|
      result = v.evaluate(validator)
      # validate_re returns nil if succeeds
      result = true if v.name == 'validate_re' && result.nil?
      result
    end

    validations.all?
  end

  # To be overwritten in children
  def multivalued?
    false
  end
end

require 'kafo/params/boolean'
require 'kafo/params/string'
require 'kafo/params/password'
require 'kafo/params/array'
require 'kafo/params/integer'
