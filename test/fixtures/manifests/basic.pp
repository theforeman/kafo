# This manifests is used for testing
#
# It has no value except of covering use cases that we must test.
#
# === Parameters
#
# $version::         some version number
# $undef::           default is undef
# $multiline::       param with multiline
#                    documentation
#                    consisting of 3 lines
# $typed::           something having it's type explicitly set
# $multivalue::      list of users
# === Advanced parameters
#
# $debug::           we have advanced parameter, yay!
# $db_type::         can be mysql or sqlite
# $base_dir::        directory to create files in
#
# ==== MySQL         condition: $db_type == 'mysql'
#
# $remote::          socket or remote connection
# $server::          hostname
#                    condition: $remote
# $username::        username
# $password::        password
# $pool_size::       DB pool size
#
# ==== Sqlite        condition: $db_type == 'sqlite'
#
# $file::            filename
#
class testing(
  $version = '1.0',
  $undef = undef,
  $multiline = undef,
  Boolean $typed = true,
  Array $multivalue = ['x', 'y'],
  Boolean $debug = true,
  Enum['mysql', 'sqlite'] $db_type = 'mysql',
  Boolean $remote = true,
  $server = 'mysql.example.com',
  $username = 'root',
  Sensitive[String[1]] $password = Sensitive('supersecret'),
  Integer $pool_size = 10,
  $file = undef,
  $base_dir = undef) {

  file { "${base_dir}/testing":
    ensure  => present,
    content => $version,
  }
}
