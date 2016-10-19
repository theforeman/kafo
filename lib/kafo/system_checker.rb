# encoding: UTF-8

module Kafo
  class SystemChecker
    attr_reader :checkers

    def self.check
      KafoConfigure.check_dirs.all? do |dir|
        new(File.join(dir, '*')).check
      end
    end

    def initialize(path)
      @checkers = Dir.glob(path).sort
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
end
