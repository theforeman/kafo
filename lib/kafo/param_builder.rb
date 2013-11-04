# encoding: UTF-8
require 'kafo/param_group'

class ParamBuilder
  def initialize(mod, data)
    @data   = data
    @module = mod
    @groups = []
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

  def build_param_groups(params)
    data = Hash[ get_parameters_groups_by_param_name ]
    data.each do |param_name, param_groups|
      param_groups.each_with_index do |group_name, i|
        param_group = find_or_build_group(group_name)
        if i + 1 < param_groups.size
          param_group.add_child find_or_build_group(param_groups[i + 1])
        end
      end

      param_group = find_or_build_group(param_groups.last)
      param       = params.detect { |p| p.name == param_name }
      param_group.add_param param unless param.nil?
    end

    # top level groups
    data.values.map(&:first).compact.uniq.map { |name| @groups.detect { |g| g.name == name } }
  end

  def build(name, data)
    param           = get_type(data[:types][name]).new(@module, name)
    param.default   = data[:values][name]
    param.doc       = data[:docs][name]
    param.groups    = data[:groups][name]
    param.condition = data[:conditions][name]
    param
  end

  private

  def get_parameters_groups_by_param_name
    @data[:groups].map do |name, groups|
      [ name, groups.select { |g| g =~ /parameters/i } ]
    end
  end

  def find_or_build_group(name)
    param_group = @groups.detect { |g| g.name == name }
    unless param_group
      param_group = ParamGroup.new(name)
      param_group.module = @module
      @groups.push param_group
    end
    param_group
  end

  def get_type(type)
    type = type.capitalize
    Params.const_defined?(type) ? Params.const_get(type) : raise(TypeError, "undefined parameter type '#{type}'")
  end
end
