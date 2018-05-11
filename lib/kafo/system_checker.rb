# encoding: UTF-8

module Kafo
  class SystemChecker
    attr_reader :checkers
    attr_reader :skipped

    def self.check(skipped=[])
      KafoConfigure.check_dirs.all? do |dir|
        new(File.join(dir, '*'), skipped).check
      end
    end

    def initialize(path, skipped)
      @checkers = Dir.glob(path).sort
      @skipped = skipped
    end

    def logger
      Logging::logger['checks']
    end

    def check
      @checkers.map! do |checker|
        if @skipped.include?(File.basename(checker))
          logger.debug "Skipping checker: #{checker}"
          true
        else
          logger.debug "Executing checker: #{checker}"
          stdout = `#{checker}`
          logger.error stdout unless stdout.empty?
          $?.exitstatus == 0
        end
      end

      @checkers.all?
    end
  end
end
