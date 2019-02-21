# Outputs a YAML hash of variable to its value, for:
#  - variables: a list of variables from params classes that have
#               already been included
#  - lookups: a list of variables to find through lookup()
#
# The result will be merged together into one hash.
class kafo_configure::dump_values($variables, $lookups) {
  $dumped_vars = dump_values($variables)
  $dumped_lookups = dump_lookups($lookups)
  $dumped = foreman_to_yaml($dumped_vars, $dumped_lookups)

  notice("\n${dumped}")
}
