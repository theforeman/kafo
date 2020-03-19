require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/mock'
require "minitest/reporters"
Minitest::Reporters.use!

require 'manifest_file_factory'
require 'config_file_factory'
require 'parser_cache_factory'
require 'test_parser'
require 'kafo'

require 'ostruct'
require 'dummy_logger'


BASIC_CONFIGURATION = <<EOS
:name: Basic
:answer_file: test/fixtures/basic_answers.yaml
:installer_dir: .
:modules_dir: test/fixtures/modules

:no_prefix: false
:mapping: {}
:order:

:dont_save_answers: true
:ignore_undocumented: true

:mapping:
  :certs:
    :dir_name: certificates
    :manifest_name: foreman
    :params_name: foreman::params
  :foreman::plugin::chef:
    :dir_name: custom
    :manifest_name: plugin/custom_chef
    :params_path: custom/plugin/chef/params.pp
    :params_name: params
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
# $multivalue::      list of users
# === Advanced parameters
#
# $debug::           we have advanced parameter, yay!
# $db_type::         can be mysql or sqlite
#
# ==== MySQL         condition: $db_type == 'mysql'
#
# $remote::          socket or remote connection
# $server::          hostname
#                    condition: $remote
# $username::        username
# $pool_size::       DB pool size
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
  Boolean $typed = true,
  Array $multivalue = ['x', 'y'],
  Boolean $debug = true,
  Enum['mysql', 'sqlite'] $db_type = 'mysql',
  Boolean $remote = true,
  $server = 'mysql.example.com',
  $username = 'root',
  Integer[1, 100] $pool_size = 10,
  $file = undef,
  $m_i_a = 'test') {

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
    Kafo::KafoConfigure.exit_handler = Kafo::ExitHandler.new
    Kafo::Logger.loggers = []
    Kafo::KafoConfigure.logger   = Kafo::Logger.new
    Kafo::KafoConfigure.module_dirs = ['test/fixtures/modules']
    Kafo::Logger.buffer.clear
    Kafo::Logger.error_buffer.clear
  end
end

def must_exit_with_code(code, &block)
  code = (Kafo::ExitHandler.new.error_codes[code] || code) if code.is_a?(Symbol)
  begin
    block.call
  rescue SystemExit => e
    _(e.status).must_equal(code)
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
    _(stdout).must_include inclusion
  end
end

def wont_be_on_stdout(output, *args)
  output.rewind
  stdout = output.read
  args.each do |inclusion|
    _(stdout).wont_include inclusion
  end
end

def fake_module(mod_name, params)
  OpenStruct.new( { :class_name => mod_name, :name => mod_name, :enabled? => true, :params => params } ).tap do |m|
    params.each { |p| p.module = m }
  end
end

def fake_param(name, value)
  OpenStruct.new( { :name => name, :value => value } )
end

def with_captured_stderr
  old_handle = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = old_handle
end
