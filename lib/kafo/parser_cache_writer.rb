module Kafo
  class ParserCacheWriter
    def self.write(modules)
      {
        :version => PARSER_CACHE_VERSION,
        :files => Hash[modules.sort.map { |m| write_module(m) }]
      }
    end

    def self.write_module(mod)
      [mod.identifier, {:data => mod.raw_data, :mtime => File.mtime(mod.manifest_path).to_i}]
    end
  end
end
