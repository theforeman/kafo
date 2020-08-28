# encoding: UTF-8

module Kafo
  class Logger

    def dump_errors
      Logging.dump_errors
    end

    def log(name, *args, &block)
      if Logging.buffering?
        Logging.to_buffer(Logging.buffer, name, args, &block)
      else
        Logging.dump_buffer(Logging.buffer) if Logging.dump_needed?
        Logging.loggers.each { |logger| logger.send name, *args, &block }
      end
    end

    %w(warn info debug).each do |name|
      define_method(name) do |*args, &block|
        log(name, *args, &block)
      end
    end

    %w(fatal error).each do |name|
      define_method(name) do |*args, &block|
        Logging.to_buffer(Logging.error_buffer, name, *args, &block)
        log(name, *args, &block)
      end
    end
  end
end
