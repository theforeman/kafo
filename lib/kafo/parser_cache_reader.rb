module Kafo
  class ParserCacheReader
    def self.new_from_file(cache_path)
      if cache_path.nil? || cache_path.empty?
        logger.debug "No parser cache configured in :parser_cache_path, skipping setup"
        return nil
      end

      unless File.exist?(cache_path)
        logger.warn "Parser cache configured at #{cache_path} is missing, skipping setup"
        return nil
      end

      parsed = YAML.load(File.read(cache_path))
      if !parsed.is_a?(Hash) || parsed[:version] != 1 || !parsed[:files].is_a?(Hash)
        logger.warn "Parser cache is from a different version of Kafo, skipping setup"
        return nil
      end

      logger.debug "Using #{cache_path} cache with parsed modules"
      new(parsed)
    end

    def self.logger
      KafoConfigure.logger
    end

    def initialize(cache)
      @cache = cache
    end

    def logger
      KafoConfigure.logger
    end

    def get(key, manifest_path)
      return nil unless @cache[:files].has_key?(key)

      if @cache[:files][key][:mtime] && File.mtime(manifest_path).to_i > @cache[:files][key][:mtime]
        logger.debug "Parser cache for #{manifest_path} is outdated, ignoring cache entry"
        return nil
      end

      @cache[:files][key][:data]
    end
  end
end
