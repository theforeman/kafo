# Find default values for variables specified as args
#
Puppet::Functions.create_function(:'kafo_configure::dump_values') do
  dispatch :dump_values do
    param 'Array[String]', :variables
    return_type 'Hash[String, Any]'
  end

  def dump_values(variables)
    scope = closure_scope
    Hash[variables.map { |var| [var, scope[var]] }]
  end
end
