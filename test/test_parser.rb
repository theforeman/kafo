class TestParser
  attr_reader :manifest_file

  def initialize(manifest = BASIC_MANIFEST)
    @manifest = manifest
    @manifest_file = ManifestFileFactory.build(manifest).path
    @cache = {}
  end

  # we use @manifest instead of manifest for testing
  def parse(manifest)
    @cache[manifest] ||= KafoParsers::Parsers.find_available.parse(manifest_file)
  end
end
