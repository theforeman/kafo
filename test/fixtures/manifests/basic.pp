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
#                    type:boolean
# $multivalue::      list of users
#                    type:array
# === Advanced parameters
#
# $debug::           we have advanced parameter, yay!
#                    type:boolean
# $db_type::         can be mysql or sqlite
# $base_dir::        directory to create files in
#
# ==== MySQL         condition: $db_type == 'mysql'
#
# $remote::          socket or remote connection
#                    type: boolean
# $server::          hostname
#                    condition: $remote
# $username::        username
# $pool_size::       DB pool size
#                    type:integer
#
# ==== Sqlite        condition: $db_type == 'sqlite'
#
# $file::            filename
#
class testing(
  $version = '1.0',
  $undef = undef,
  $multiline = undef,
  $typed = true,
  $multivalue = ['x', 'y'],
  $debug = true,
  $db_type = 'mysql',
  $remote = true,
  $server = 'mysql.example.com',
  $username = 'root',
  $pool_size = 10,
  $file = undef,
  $base_dir = undef) {

  file { "${base_dir}/testing":
    ensure  => present,
    content => $version,
  }
}
