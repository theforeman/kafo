# encoding: UTF-8

class SystemChecker
  def self.check
    new(File.join(KafoConfigure.root_dir, 'checks', '*')).check
  end

  def initialize(path)
    @checkers = Dir.glob(path)
  end

  def logger
    Logging::logger['checks']
  end

  def check
    @checkers.map! do |checker|
      logger.debug "Executing checker: #{checker}"
      stdout = `#{checker}`
      logger.error stdout unless stdout.empty?
      $?.exitstatus == 0
    end

    @checkers.all?
  end
end
