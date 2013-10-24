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
  $debug = true) {

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
      it { keys.must_include :values }
      it { keys.must_include :validations }
      it { keys.must_include :docs }
      it { keys.must_include :parameters }
      it { keys.must_include :types }
      it { keys.must_include :groups }
      it { keys.must_include :conditions }
    end

    let(:parameters) { data[:parameters] }
    describe 'parsed parameters' do
      it { parameters.must_include 'version' }
      it { parameters.must_include 'undocumented' }
      it { parameters.must_include 'undef' }
      it { parameters.must_include 'debug' }
      it { parameters.wont_include 'documented' }
    end

    describe "parsed values" do
      let(:values) { data[:values] }
      it 'includes values for all parameters' do
        parameters.each { |p| values.keys.must_include p }
      end
      it { values['version'].must_equal '1.0' }
      it { values['undef'].must_equal :undef }
      it { values['debug'].must_equal true }
    end

    describe "parsed validations" do
      let(:validations) { data[:validations] }
      it { validations.size.must_equal 1 }
      it { validations.map(&:name).each { |v| v.must_equal 'validate_string' } }
      it { validations.each { |v| v.must_be_kind_of Puppet::Parser::AST::Function } }
    end

    describe "parsed documentation" do
      let(:docs) { data[:docs]}
      it { docs.keys.must_include 'documented' }
      it { docs.keys.must_include 'version' }
      it { docs.keys.must_include 'undef' }
      it { docs.keys.wont_include 'm_i_a' }
      it { docs.keys.wont_include 'undocumented' }
      it { docs['version'].must_equal ['some version number'] }
      it { docs['multiline'].must_equal ['param with multiline', 'documentation', 'consisting of 3 lines'] }
      it { docs['typed'].wont_include 'type:bool' }
    end

    describe "parsed groups" do
      let(:groups) { data[:groups] }
      it { groups['version'].must_equal ['Parameters'] }
      it { groups['debug'].must_equal ['Advanced parameters'] }
      it { groups['server'].must_equal ['Advanced parameters', 'MySQL'] }
      it { groups['file'].must_equal ['Advanced parameters', 'Sqlite'] }
      it { groups['log_level'].must_equal ['Extra parameters'] }
    end

    describe "parsed types" do
      let(:types) { data[:types] }
      it { types['version'].must_equal 'string' }
      it { types['typed'].must_equal 'boolean' }
      it { types['remote'].must_equal 'boolean' }
    end

    describe "parsed conditions" do
      let(:conditions) { data[:conditions] }
      it { conditions['version'].must_be_nil }
      it { conditions['typed'].must_be_nil }
      it { conditions['remote'].must_equal '$db_type == \'mysql\'' }
      it { conditions['server'].must_equal '$db_type == \'mysql\' && $remote' }
      it { conditions['username'].must_equal '$db_type == \'mysql\'' }
      it { conditions['password'].must_equal '$db_type == \'mysql\' && $username != \'root\'' }
    end
  end
end
