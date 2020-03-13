require 'open3'

module Kafo
  class BaseContext
    def facts
      self.class.facts
    end

    private

    def self.symbolize(data)
      case data
      when Hash
        Hash[data.map { |key, value| [key.to_sym, symbolize(value)] }]
      when Array
        data.map { |v| symbolize(v) }
      else
        data
      end
    end

    def self.clear_caches
      @facts = nil
      @facter_path = nil
    end

    def self.facts
      @facts ||= begin
        result = run_command("#{facter_path} --json")
        symbolize(JSON.load(result) || {})
      end
    end

    def self.facter_path
      @facter_path ||= PuppetCommand.search_puppet_path('facter')
    end

    def self.run_command(command)
      stdout, _stderr, _status = Open3.capture3(*PuppetCommand.format_command(command))
      stdout
    end
  end
end
