class TestParser

  def initialize(manifest = BASIC_MANIFEST)
    @manifest = manifest
  end

  # we use @manifest instead of manifest for testing
  def parse(manifest)
    self.class.parse(@manifest)
  end

  def self.parse(manifest)
    PuppetModuleParser.parse(ManifestFileFactory.build(manifest).path)
  end
end
