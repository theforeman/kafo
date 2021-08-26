# encoding: UTF-8
require 'kafo/logging'

module Kafo
  class Logger

    attr_reader :logger, :name

    def initialize(name = 'root')
      @name = name
      @logger = (name == 'root') ? Logging.root_logger : Logging.add_logger(name)
    end

    def log(level, *args, &block)
      if Logging.buffering?
        if block_given?
          data = yield
        else
          data = args
        end

        Logging.to_buffer(@name, ::Logging::LogEvent.new(@name, ::Logging::LEVELS[level.to_s], data, false))
      else
        Logging.dump_buffer if Logging.dump_needed?
        @logger.send(level, *args, &block)
      end
    end

    Logging::LOG_LEVELS.each do |level|
      define_method(level) do |*args, &block|
        log(level, *args, &block)
      end
    end
  end
end
