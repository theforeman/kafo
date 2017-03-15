# Outputs a YAML hash of variable to its value, for:
#  - variables: a list of variables from params classes that have
#               already been included
#  - lookups: a list of variables to find through lookup()
#
# The result will be merged together into one hash.
class kafo_configure::dump_values($variables, $lookups) {
  $dumped_vars = dump_values($variables)

  # Data lookups are only supported on Puppet 4 or higher, however depend on
  # 4.5.0 which fixes PUP-6230 where missing data correctly returns the
  # default/undef instead of an empty hash.
  if versioncmp($::puppetversion, '4.5') >= 0 {
    $dumped_lookups = dump_lookups($lookups)
    $dumped = to_yaml($dumped_vars, $dumped_lookups)
  } else {
    $dumped = to_yaml($dumped_vars)
  }

  notice("\n${dumped}")
}
