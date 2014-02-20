# encoding: UTF-8
require 'puppet'
require 'kafo/doc_parser'

module Kafo
  # Based on ideas from puppet-parse by Johan van den Dorpe
  # we don't build any tree structure since e.g. params from doc does not
  # have to be defined in puppet DSL and vice versa, we just gather all info
  # we can read from the whole manifest
  class PuppetModuleParser
    def self.parse(file)
      content = new(file)
      docs    = content.docs

      data              = {
          :values      => content.values,
          :validations => content.validations
      }
      data[:parameters] = data[:values].keys
      data.merge!(docs)
      data
    end

    def initialize(file)
      @file = file
      raise ModuleName, "File not found #{file}, check you answer file" unless File.exists?(file)
      Puppet.settings[:confdir] ||= '/' # just some stubbing
      if Puppet::Node::Environment.respond_to?(:create)
        env = Puppet::Node::Environment.create(:production, [], '')
      else
        env = Puppet::Node::Environment.new(:production)
      end
      parser = Puppet::Parser::Parser.new(env)
      parser.import(@file)

      # Find object corresponding to class defined in init.pp in list of hostclasses
      parser.environment.known_resource_types.hostclasses.each do |ast_objects|
        ast_type = ast_objects.last
        @object = ast_type if ast_type.file == file
      end

      parser
    end

    # TODO - store parsed object type (Puppet::Parser::AST::Variable must be dumped later)
    def values
      parameters = {}
      arguments  = @object.respond_to?(:arguments) ? @object.arguments : {}
      arguments.each { |k, v| parameters[k] = v.respond_to?(:value) ? v.value : nil }
      parameters
    end

    def validations(param = nil)
      @object.code.select { |stmt| stmt.is_a?(Puppet::Parser::AST::Function) && stmt.name =~ /^validate_/ }
    end

    # returns data in following form
    # {
    #   :docs => { $param1 => 'documentation without types and conditions'}
    #   :types => { $param1 => 'boolean'},
    #   :groups => { $param1 => ['Parameters', 'Advanced']},
    #   :conditions => { $param1 => '$db_type == "mysql"'},
    # }
    def docs
      data = { :docs => {}, :types => {}, :groups => {}, :conditions => {} }
      if @object.nil?
        raise DocParseError, "no documentation found for manifest #{@file}, parsing error?"
      elsif !@object.doc.nil?
        parser            = DocParser.new(@object.doc).parse
        data[:docs]       = parser.docs
        data[:groups]     = parser.groups
        data[:types]      = parser.types
        data[:conditions] = parser.conditions
      end
      data
    end
  end
end
