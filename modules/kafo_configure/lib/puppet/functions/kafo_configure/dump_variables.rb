# Find default values for variables specified as args
#
Puppet::Functions.create_function(:'kafo_configure::dump_variables') do
  dispatch :dump_variables do
    param 'Array[String]', :variables
    return_type 'Hash[String, Any]'
  end

  def dump_variables(variables)
    scope = closure_scope
    Hash[variables.map { |var| [var, unwrap(scope[var])] }]
  end

  private

  def unwrap(value)
    value.respond_to?(:unwrap) ? value.unwrap : value
  end
end
