class ParamBuilder
  ATTRIBUTE_RE = /^(type):(.*)/

  def initialize(mod, data)
    @data   = data
    @module = mod
  end

  def validate
    parameters = @data['parameters'].keys.sort
    docs       = @data['docs'].keys.sort
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
    @data['parameters'].keys.map do |param_name|
      build(param_name, @data['parameters'][param_name], @data['docs'][param_name])
    end
  end

  def build(name, default, docs)
    param         = get_type(docs).new(@module, name)
    param.default = default
    param.doc     = get_documentation(docs)
    param
  end

  private

  def get_documentation(docs)
    return nil if docs.nil?
    docs.select { |line| line !~ ATTRIBUTE_RE }
  end

  def get_type(docs)
    type = (get_attributes(docs)[:type] || '').capitalize
    type.empty? || !Params.const_defined?(type) ? Params::String : Params.const_get(type, false)
  end

  def get_attributes(docs)
    data = {}
    return data if docs.nil?

    docs.each do |line|
      if line =~ ATTRIBUTE_RE
        data[$1.to_sym] = $2
      end
    end
    data
  end
end
