require 'tempfile'

class ConfigFileFactory
  @configs = {}
  @answers = {}

  def self.build(key, content)
    @configs[key] ||= build_file(content)
  end

  def self.build_file(content)
    match = /:answer_file:\ (.*)/.match(content)
    if match
      content.gsub!(/:answer_file:\ .*/, ":answer_file: #{answers(match[1]).path}")
    end
    temp_file('testing_config', content)
  end

  def self.answers(file)
    @answers[file] ||= temp_file('testing_ansers', File.read(file))
  end

  def self.temp_file(name, content)
    f = Tempfile.open(['testing_config', '.yaml'])
    f.write content
    f.close
    f
  end
end
