# we require separate STDERR
require 'open3'

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
      Open3.popen3(checker) { |stdin, stdout, stderr, wait_thr|
        stdout = stdout.read
        stderr = stderr.read
        logger.debug stdout unless stdout.empty?
        logger.error stderr unless stderr.empty?
        wait_thr.value.success?
      }
    end

    @checkers.all?
  end
end
