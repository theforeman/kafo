# encoding: UTF-8
module Kafo
  class Validator

    def self.prepare_functions
      return true if @reset || !Puppet::Parser::Functions.respond_to?(:reset)
      Puppet::Parser::Functions.reset
      @reset = true
    end

    def initialize(params)
      self.class.prepare_functions
      validate_files = KafoConfigure.modules_dir + '/*/lib/puppet/parser/functions/validate_*.rb'
      is_function_files = KafoConfigure.modules_dir + '/*/lib/puppet/parser/functions/is_*.rb'
      definitions = Dir.glob(validate_files) + Dir.glob(is_function_files)

      definitions.each do |file|
        require File.expand_path(file)
      end

      @params = params
      @logger = KafoConfigure.logger

      @cache ||= Hash.new do |hash, key|
        @logger.debug "Looked for #{key}"
        param     = @params.select { |p| p.name == key.to_s }.first
        hash[key] = param.nil? ? nil : param.value
      end
    end

    def lookupvar(name, options = {})
      @cache[name]
    end

    # for puppet >= 3
    def include?(value)
      true
    end

    # for puppet >= 3
    def [](value, *args)
      lookupvar(value)
    end

    def method_missing(method, *args, &block)
      method.to_s =~ /^function_(.*)$/
      super unless $1
      super unless Puppet::Parser::Functions.function($1)
      # In odd circumstances, this might not end up defined by the previous
      # method, so we might as well be certain.
      if engine.respond_to? method
        @logger.debug "calling #{method.inspect} with #{args.inspect}"
        engine.send(method, *args)
        true
      else
        raise Puppet::DevError, "Function #{$1} not defined despite being loaded!"
      end
    rescue Puppet::ParseError => e
      @logger.error e.message
      return false
    end

    private

    def engine
      @engine ||= begin
        klass = Class.new
        env = Puppet::PUPPETVERSION.start_with?('2.') ? nil : lookup_current_environment
        klass.send :include, Puppet::Parser::Functions.environment_module(env)
        klass.new
      end
    end

    def lookup_current_environment
      @current_environment ||= Puppet.respond_to?(:lookup) ? Puppet.lookup(:current_environment) : Puppet::Node::Environment.current
    end
  end
end
