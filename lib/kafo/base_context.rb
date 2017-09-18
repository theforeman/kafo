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
        symbolize(JSON.load(`#{facter_path} --json`) || {})
      end
    end

    def self.facter_path
      @facter_path ||= PuppetCommand.search_puppet_path('facter')
    end
  end
end
