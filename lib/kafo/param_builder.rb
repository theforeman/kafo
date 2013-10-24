# encoding: UTF-8
class ParamBuilder
  ATTRIBUTE_RE = /^(type):(.*)/

  def initialize(mod, data)
    @data   = data
    @module = mod
  end

  def validate
    return true if KafoConfigure.config.app[:ignore_undocumented]

    parameters = @data[:parameters].sort
    docs       = @data[:docs].keys.sort
    if parameters == docs
      return true
    else
      undocumented = parameters - docs
      raise ConfigurationException, "undocumented parameters in #{@module.name}: #{undocumented.join(', ')}" unless undocumented.empty?
      deleted = docs - parameters
      raise ConfigurationException, "documentation mentioned unknown parameters in #{@module.name}: #{deleted.join(', ')}" unless deleted.empty?
      raise ConfigurationException, "unknown error in configuration in #{@module.name}"
    end
  end

  def build_params
    @data[:parameters].map do |param_name|
      build(param_name, @data)
    end
  end

  def build(name, data)
    param         = get_type(data[:types][name]).new(@module, name)
    param.default = data[:values][name]
    param.doc     = data[:docs][name]
    param
  end

  private

  # we don't want to be strict so people can define their own parameters
  # down side of this is when you have typo in your type (e.g. type:bol)
  # it will be treated as a String
  def get_type(type)
    type = type.capitalize
    Params.const_defined?(type) ? Params.const_get(type) : Params::String
  end
end
