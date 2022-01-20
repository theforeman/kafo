# Find values via data lookups for class parameters
#
# Wraps the lookup() function for data lookups of class parameters without
# inline defaults.
#
Puppet::Functions.create_function(:'kafo_configure::dump_lookups') do
  dispatch :dump_lookups do
    param 'Array[String]', :parameters
    return_type 'Hash[String, Any]'
  end

  def dump_lookups(parameters)
    Hash[parameters.map { |param| [param, lookup(param)] }]
  end

  private

  def lookup(param)
    value = call_function('lookup', [param], 'default_value' => nil)
    value.respond_to?(:unwrap) ? value.unwrap : value
  end
end
