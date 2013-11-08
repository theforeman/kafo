require 'tempfile'

class ManifestFileFactory
  @manifests = {}

  def self.build(content)
    key = content.hash
    @manifests[key] or @manifests[key] = build_file(content)
    @manifests[key]
  end

  def self.build_file(content)
    f = Tempfile.new(['testing_manifest', '.pp'])
    f.write content
    f.close
    f
  end
end
