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
        Logging.to_buffer(@name, level, args, &block)
      else
        Logging.dump_buffer if Logging.dump_needed?
        @logger.send(level, *args, &block)
      end
    end

    %w(warn info debug fatal error).each do |level|
      define_method(level) do |*args, &block|
        log(level, *args, &block)
      end
    end
  end
end
