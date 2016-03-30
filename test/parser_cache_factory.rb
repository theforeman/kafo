require 'tempfile'
require 'yaml'

class ParserCacheFactory
  @caches = {}

  def self.build(content)
    content = {:version => 1}.merge(content).to_yaml if content.is_a?(Hash)
    key = content.hash
    @caches[key] or @caches[key] = build_file(content)
    @caches[key]
  end

  def self.build_file(content)
    f = Tempfile.new(['testing_cache', '.json'])
    f.write content
    f.close
    f
  end
end
