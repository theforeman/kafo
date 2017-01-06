# This manifests is used for testing
#
# It has no value except of covering use cases that we must test.
#
# @param version    some version number
# @param undef      default is undef
# @param multiline  param with multiline
#                   documentation
#                   consisting of 3 lines
# @param typed      something having its type explicitly set
# @param multivalue list of users
#
# @param debug      we have advanced parameter, yay!
#                   group:Advanced parameters
# @param db_type    can be mysql or sqlite
#                   group:Advanced parameters
# @param base_dir   directory to create files in
#                   group:Advanced parameters
#
# @param remote     socket or remote connection
#                   group: Advanced parameters, MySQL
# @param server     hostname
#                   condition: $remote
#                   group: Advanced parameters, MySQL
# @param username   username
#                   group: Advanced parameters, MySQL
# @param pool_size  DB pool size
#                   group: Advanced parameters, MySQL
#
# @param file       filename
#                   group: Advanced parameters, Sqlite
#
class testing(
  Any $version,
  Optional[Integer] $undef,
  Optional[String] $multiline,
  Boolean $typed,
  Array[String] $multivalue,
  Boolean $debug,
  Enum['mysql', 'sqlite'] $db_type,
  String $base_dir,
  Boolean $remote,
  String $server,
  String $username,
  Integer $pool_size,
  Optional[String] $file) {

  file { "${base_dir}/testing":
    ensure  => present,
    content => $version,
  }
}
