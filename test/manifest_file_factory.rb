require 'tempfile'

class ManifestFileFactory
  @manifests = {}

  def self.build(content)
    @manifests['basic'] or @manifests['basic'] = build_file(content)
  end

  def self.build_file(content)
    f = Tempfile.new(['testing_manifest', '.pp'])
    f.write content
    f.close
    f
  end
end
