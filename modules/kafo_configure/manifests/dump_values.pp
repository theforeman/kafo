# Outputs a YAML hash of variable to its value, for:
#  - variables: a list of variables from params classes that have
#               already been included
#  - lookups: a list of variables to find through lookup()
#
# The result will be merged together into one hash.
#
#  @param variables a list of variables from params classes that have
#                   already been included
#  @param lookups a list of variables to find through lookup()
class kafo_configure::dump_values(
  Array[String] $variables = [],
  Array[String] $lookups = [],
) {
  $dumped_vars = kafo_configure::dump_variables($variables)
  $dumped_lookups = kafo_configure::dump_lookups($lookups)
  $dumped = kafo_configure::to_yaml($dumped_vars, $dumped_lookups)

  notice("\n${dumped}")
}
