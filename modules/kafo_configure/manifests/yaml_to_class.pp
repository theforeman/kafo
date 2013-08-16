# Takes a key to lookup in the installation answers file
# - If it's a hash, declare a class with those parameters
# - If it's true or "true" declare the default parameters for that class
# - If it's false or "false" ignore it
# - Otherwise fail with error
#
define kafo_configure::yaml_to_class {

  $classname = class_name($name)

  if is_hash($kafo_configure::params[$name]) {
    # The quotes around $classname seem to matter to puppet's parser...
    $params = { "${classname}" => $kafo_configure::params[$name] }
    create_resources( 'class', $params )
  } elsif $kafo_configure::params[$name] == true {
    $params = { "${classname}" => {} }
    create_resources( 'class', $params )
  } elsif ! $kafo_configure::params[$name] or $kafo_configure::params[$name] == "false" {
    debug("${::hostname}: not including $name")
  } else {
    fail("${::hostname}: unknown type of answers data for $name")
  }

}
