# Find values via data lookups for class parameters
#
# Wraps the lookup() function for data lookups of class parameters without
# inline defaults.
#
Puppet::Functions.create_function(:dump_lookups) do
  dispatch :dump_lookups do
    param 'Array[String]', :parameters
  end

  def dump_lookups(parameters)
    Hash[parameters.map { |param| [param, call_function('lookup', [param], 'default_value' => nil)] }]
  end
end
