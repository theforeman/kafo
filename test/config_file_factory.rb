require 'tempfile'

class ConfigFileFactory
  @configs = {}

  def self.build(key, content)
    @configs[key] or @configs[key] = build_file(content)
  end

  def self.build_file(content)
    f = Tempfile.open(['testing_config', '.yaml'])
    f.write content
    f.close
    f
  end
end
