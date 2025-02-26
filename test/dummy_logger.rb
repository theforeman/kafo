class DummyLogger

  attr_accessor :name

  LEVELS = %w(fatal error warn info debug)

  def initialize(name = 'DummyLogger')
    LEVELS.each { |l| instance_variable_set("@#{l}", StringIO.new) }
    @name = name
  end

  LEVELS.each do |level|
    define_method(level) do |*messages|
      current_level = instance_variable_get("@#{level}")
      messages.empty? ? current_level : current_level.puts(messages.first)
    end
  end

  def rewind
    LEVELS.each { |l| instance_variable_get("@#{l}").rewind }
  end

  def dump_errors
    true
  end
end
