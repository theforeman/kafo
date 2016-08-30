require 'kafo/version'

module Kafo
  class ParserCacheReader
    def self.new_from_file(cache_paths)
      cache_paths = [cache_paths].compact unless cache_paths.is_a?(Array)
      if cache_paths.empty?
        logger.debug "No parser cache(s) configured in :parser_cache_path, skipping setup"
        return nil
      end

      non_existent = cache_paths.select { |path| !File.exist?(path) }
      unless non_existent.empty?
        logger.warn "Parser cache(s) configured at #{non_existent.join(", ")} are missing, skipping setup"
        return nil
      end

      parsed = cache_paths.map { |path| YAML.load(File.read(File.expand_path(path))) }

      parsed.each_with_index do |cache, i|
        if !cache.is_a?(Hash) || cache[:version] != PARSER_CACHE_VERSION || !cache[:files].is_a?(Hash)
          logger.warn "Parser cache #{cache_paths[i]} is from a different version of Kafo, skipping setup"
          return nil
        end
      end

      logger.debug "Using #{cache_paths.join(", ")} cache with parsed modules"

      merged_cache = {
        :version => PARSER_CACHE_VERSION,
        :files => parsed.map { |cache| cache[:files] }.reduce({}) { |ret, files| ret.merge!(files) }
      }

      new(merged_cache)
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
