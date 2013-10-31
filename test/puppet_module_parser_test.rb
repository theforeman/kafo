require 'test_helper'

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

describe PuppetModuleParser do
  describe ".parse(file)" do
    let(:data) { PuppetModuleParser.parse(ManifestFileFactory.build(BASIC_MANIFEST).path) }

    describe 'data structure' do
      let(:keys) { data.keys }
      specify { keys.must_include :values }
      specify { keys.must_include :validations }
      specify { keys.must_include :docs }
      specify { keys.must_include :parameters }
      specify { keys.must_include :types }
      specify { keys.must_include :groups }
      specify { keys.must_include :conditions }
    end

    let(:parameters) { data[:parameters] }
    describe 'parsed parameters' do
      specify { parameters.must_include 'version' }
      specify { parameters.must_include 'undocumented' }
      specify { parameters.must_include 'undef' }
      specify { parameters.must_include 'debug' }
      specify { parameters.wont_include 'documented' }
    end

    describe "parsed values" do
      let(:values) { data[:values] }
      it 'includes values for all parameters' do
        parameters.each { |p| values.keys.must_include p }
      end
      specify { values['version'].must_equal '1.0' }
      specify { values['undef'].must_equal :undef }
      specify { values['debug'].must_equal true }
    end

    describe "parsed validations" do
      let(:validations) { data[:validations] }
      specify { validations.size.must_equal 1 }
      specify { validations.map(&:name).each { |v| v.must_equal 'validate_string' } }
      specify { validations.each { |v| v.must_be_kind_of Puppet::Parser::AST::Function } }
    end

    describe "parsed documentation" do
      let(:docs) { data[:docs]}
      specify { docs.keys.must_include 'documented' }
      specify { docs.keys.must_include 'version' }
      specify { docs.keys.must_include 'undef' }
      specify { docs.keys.wont_include 'm_i_a' }
      specify { docs.keys.wont_include 'undocumented' }
      specify { docs['version'].must_equal ['some version number'] }
      specify { docs['multiline'].must_equal ['param with multiline', 'documentation', 'consisting of 3 lines'] }
      specify { docs['typed'].wont_include 'type:bool' }
    end

    describe "parsed groups" do
      let(:groups) { data[:groups] }
      specify { groups['version'].must_equal ['Parameters'] }
      specify { groups['debug'].must_equal ['Advanced parameters'] }
      specify { groups['server'].must_equal ['Advanced parameters', 'MySQL'] }
      specify { groups['file'].must_equal ['Advanced parameters', 'Sqlite'] }
      specify { groups['log_level'].must_equal ['Extra parameters'] }
    end

    describe "parsed types" do
      let(:types) { data[:types] }
      specify { types['version'].must_equal 'string' }
      specify { types['typed'].must_equal 'boolean' }
      specify { types['remote'].must_equal 'boolean' }
    end

    describe "parsed conditions" do
      let(:conditions) { data[:conditions] }
      specify { conditions['version'].must_be_nil }
      specify { conditions['typed'].must_be_nil }
      specify { conditions['remote'].must_equal '$db_type == \'mysql\'' }
      specify { conditions['server'].must_equal '$db_type == \'mysql\' && $remote' }
      specify { conditions['username'].must_equal '$db_type == \'mysql\'' }
      specify { conditions['password'].must_equal '$db_type == \'mysql\' && $username != \'root\'' }
    end
  end
end
