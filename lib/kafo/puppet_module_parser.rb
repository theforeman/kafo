require 'puppet'
require 'rdoc'
# Based on ideas from puppet-parse by Johan van den Dorpe
class PuppetModuleParser
  def self.parse(file)
    content = new(file)

    {
        'parameters'  => content.parameters,
        'docs'        => content.docs,
        'validations' => content.validations
    }
  end

  def initialize(file)
    raise ModuleName, "File not found #{file}, check you answer file" unless File.exists?(file)
    parser = Puppet::Parser::Parser.new('production')
    values = Puppet.settings.instance_variable_get('@values')
    values[:production][:confdir] ||= '/' # just some stubbing
    parser.import(file)

    # Find object in list of hostclasses
    parser.environment.known_resource_types.hostclasses.each do |x|
      @object = x.last if x.last.file == file
    end
    # Find object in list of definitions
    parser.environment.known_resource_types.definitions.each do |x|
      @object = x.last if x.last.file == file
    end
  end

  def parameters
    parameters = {}
    arguments  = @object.respond_to?(:arguments) ? @object.arguments : {}
    arguments.each { |k, v| parameters[k] = v.respond_to?(:value) ? v.value : nil }
    parameters
  end

  def klass
    @object.name if @object.class.respond_to?(:name)
  end

  def validations(param = nil)
    @object.code.select { |stmt| stmt.is_a?(Puppet::Parser::AST::Function) && stmt.name =~ /^validate_/ }
  end

  def docs
    docs = {}
    if !@object.doc.nil?
      rdoc  = RDoc::Markup.parse(@object.doc)
      items = rdoc.parts.select { |part| part.respond_to?(:items) }.map(&:items).flatten
      items.each do |item|
        # Skip rdoc items that aren't paragraphs
        next unless (item.parts.to_s.scan("RDoc::Markup::Paragraph") == ["RDoc::Markup::Paragraph"])
        # RDoc (>= 4) makes label an array
        label = item.label.is_a?(Array) ? item.label.first : item.label
        # Documentation must be a list - if there's no label then skip
        next if label.nil?
        key       = label.tr('^A-Za-z0-9_-', '')
        docs[key] = item.parts.first.parts.map!(&:strip)
      end
    end
    docs
  end
end
