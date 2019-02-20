# Returns the given argument as a string containing YAML, with an end of
# document marker.
#
Puppet::Functions.create_function(:'kafo_configure::to_yaml') do
  dispatch :to_yaml do
    param 'Hash', :variables
    param 'Hash', :lookups
    return_type 'String'
  end

  def to_yaml(variables, lookups)
    dump = variables.merge(lookups)
    YAML.dump(dump) + "\n...\n"
  end
end
