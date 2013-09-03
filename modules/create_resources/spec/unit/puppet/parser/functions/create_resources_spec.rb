require 'puppet'
require 'spec_helper'

describe 'function for dynamically creating resources' do

  def setup_scope
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("floppy", :environment => 'production'))
    if Puppet.version =~ /^3\./
      @scope = Puppet::Parser::Scope.new(@compiler)
    else
      @scope = Puppet::Parser::Scope.new(:compiler => @compiler)
    end
    @topscope = @topscope
    @scope.parent = @topscope
    Puppet::Parser::Functions.function(:create_resources)
  end

  describe 'basic tests' do

    before :each do
      setup_scope
    end

    it "should exist" do
      Puppet::Parser::Functions.function(:create_resources).should == "function_create_resources"
    end
    it 'should require two arguments' do
      lambda { @scope.function_create_resources(['foo']) }.should raise_error(ArgumentError, 'create_resources(): wrong number of arguments (1; must be 2 or 3)')
    end
  end

  describe 'when creating native types' do
    before :each do
      Puppet[:code]=
'
class t {}
notify{test:}
'
      setup_scope
    end
    it 'empty hash should not cause resources to be added' do

      @scope.function_create_resources(['file', {}])
      @compiler.catalog.resources.size == 1
    end
    it 'should be able to add' do
      @scope.function_create_resources(['file', {'/etc/foo'=>{'ensure'=>'present'}}])
      @compiler.catalog.resource(:file, "/etc/foo")['ensure'].should == 'present'
    end
    it 'should accept multiple types' do
      type_hash = {}
      type_hash['notify'] = {'message' => 'one'}
      type_hash['user']   = {'home' => true}
      @scope.function_create_resources(['notify', type_hash])
      @compiler.catalog.resource(:notify, "notify")['message'].should == 'one'
      @compiler.catalog.resource(:notify, "user")['home'].should == true
    end
    it 'should fail to add non-existing type' do
      lambda {
        @scope.function_create_resources(['fooper', {}]) }.should raise_error(ArgumentError, 'could not create resource of unknown type fooper')
    end
    before :each do
      Puppet[:code]=
'
class t {}
define foo($one){notify{$name: message => $one}}
notify{test:}
'
      setup_scope
      Puppet::Parser::Functions.function(:create_resources)
    end
    it 'should be able to create defined resoure types' do
      @scope.function_create_resources(['foo', {'blah'=>{'one'=>'two'}}])
      # still have to compile for this to work...
      # I am not sure if this constraint ruins the tests
      @scope.compiler.compile
      @compiler.catalog.resource(:notify, "blah")['message'].should == 'two'
    end
    it 'should fail if defines are missing params' do
      @scope.function_create_resources(['foo', {'blah'=>{}}])
      lambda { @scope.compiler.compile }.should raise_error(Puppet::ParseError, /Must pass one/)
    end
    it 'should be able to add multiple defines' do
      hash = {}
      hash['blah'] = {'one' => 'two'}
      hash['blaz'] = {'one' => 'three'}
      @scope.function_create_resources(['foo', hash])
      # still have to compile for this to work...
      # I am not sure if this constraint ruins the tests
      @scope.compiler.compile
      @compiler.catalog.resource(:notify, "blah")['message'].should == 'two'
      @compiler.catalog.resource(:notify, "blaz")['message'].should == 'three'
    end
  end
  describe 'when creating classes' do
    before :each do
      Puppet[:code]=
'
class t {}
class bar($one){notify{test: message => $one}}
notify{tester:}
'
      setup_scope
      Puppet::Parser::Functions.function(:create_resources)
    end
    it 'should be able to create classes' do
      @scope.function_create_resources(['class', {'bar'=>{'one'=>'two'}}])
      @scope.compiler.compile
      @compiler.catalog.resource(:notify, "test")['message'].should == 'two'
      @compiler.catalog.resource(:class, "bar").should_not be_nil#['message'].should == 'two'
    end
    it 'should fail to create non-existing classes' do
      lambda { @scope.function_create_resources(['class', {'blah'=>{'one'=>'two'}}]) }.should raise_error(ArgumentError ,'could not find hostclass blah')
    end
  end
end
