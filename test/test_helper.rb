require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/mock'

require 'manifest_file_factory'
require 'config_file_factory'
require 'test_parser'
require 'kafo'

require 'ostruct'


BASIC_CONFIGURATION = <<EOS
:answer_file: test/fixtures/basic_answers.yaml
:installer_dir: .
:modules_dir: test/fixtures/modules

:no_prefix: false
:mapping: {}
:order:

:default_values_dir: /tmp

:dont_save_answers: true
:ignore_undocumented: true

:mapping: []
:password: secret
EOS

BASIC_MANIFEST = <<EOS
# This manifests is used for testing
#
# It has no value except of covering use cases that we must test.
#
# === Parameters
#
# $version::         some version number
# $documented::      something that is documented but not used
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
#
# ==== MySQL         condition: $db_type == 'mysql'
#
# $remote::          socket or remote connection
#                    type: boolean
# $server::          hostname
#                    condition: $remote
# $username::        username
# $password::        type:password
#                    condition:$username != 'root'
#
# ==== Sqlite        condition: $db_type == 'sqlite'
#
# $file::            filename
#
# === Extra parameters
#
# $log_level::       we can get up in levels
# $m_i_a::
#
class testing(
  $version = '1.0',
  $undocumented = 'does not have documentation',
  $undef = undef,
  $multiline = undef,
  $typed = true,
  $multivalue = ['x', 'y'],
  $debug = true,
  $db_type = 'mysql',
  $remote = true,
  $server = 'mysql.example.com',
  $username = 'root',
  $password = 'toor',
  $file = undef,
  $m_i_a = 'test') {

  validate_string($undocumented)
  if $version == '1.0' {
    # this must be ignored since we can't evaluate conditions
    validate_bool($undef)
  }

  package {"testing":
    ensure => present
  }
}
EOS

MANIFEST_WITHOUT_PRIMARY_GROUP = <<EOS
# This manifests has no primary group
#
# === Basic parameters:
#
# $version::         some version number
#
# === Advanced parameters:
#
# $documented::      something that is documented
#
class testing2(
  $version    = '1.0',
  $documented = 'test') {

  package {"testing":
    ensure => present
  }
}
EOS

MANIFEST_WITHOUT_ANY_GROUP = <<EOS
# This manifests has no primary group
#
# $version::         some version number
# $documented::      something that is documented
#
class testing3(
  $version    = '1.0',
  $documented = 'test') {

  package {"testing":
    ensure => present
  }
}
EOS

NO_DOC_MANIFEST = <<EOS
class testing4(
  $version    = '1.0',
  $documented = 'test') {

  package {"testing":
    ensure => present
  }
}
EOS

class Minitest::Spec
  before do
    Kafo::KafoConfigure.config   = Kafo::Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
    Kafo::KafoConfigure.root_dir = File.dirname(__FILE__)
    Kafo::KafoConfigure.logger   = Kafo::Logger.new
    Kafo::KafoConfigure.modules_dir = 'test/fixtures/modules'
    Kafo::Logger.loggers = []
  end
end

def must_exit_with_code(code, &block)
  begin
    block.call
  rescue SystemExit => e
    e.status.must_equal(code)
  rescue EOFError => e
    assert false, "input does not make process to exit normally (#{e.message})"
  end
end

def must_not_raise_eof(input, output, &block)
  begin
    block.call
  rescue EOFError => e
    input.rewind
    output.rewind
    assert false, "input does not make process to exit normally (#{e.message})\ninput: #{input.read}\noutput: #{output.read}"
  end
end

def must_be_on_stdout(output, *args)
  output.rewind
  stdout = output.read
  args.each do |inclusion|
    stdout.must_include inclusion
  end
end

def wont_be_on_stdout(output, *args)
  output.rewind
  stdout = output.read
  args.each do |inclusion|
    stdout.wont_include inclusion
  end
end
