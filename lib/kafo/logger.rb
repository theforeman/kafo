# encoding: UTF-8
require 'fileutils'
require 'logging'

module Kafo
  class Logger
    class << self
      attr_writer :loggers

      def loggers
        @loggers ||= []
      end

      def buffer
        @buffer ||= []
      end

      def error_buffer
        @error_buffer ||= []
      end
    end

    PATTERN = "[%5l %d %c] %m\n"
    Logging.color_scheme('bright',
                         :levels => {
                             :info  => :green,
                             :warn  => :yellow,
                             :error => :red,
                             :fatal => [:white, :on_red]
                         },
                         :date   => :blue,
                         :logger => :cyan,
                         :line   => :yellow,
                         :file   => :yellow,
                         :method => :yellow
    )
    COLOR_LAYOUT   = Logging::Layouts::Pattern.new(:pattern => PATTERN, :color_scheme => 'bright')
    NOCOLOR_LAYOUT = Logging::Layouts::Pattern.new(:pattern => PATTERN, :color_scheme => nil)

    def self.setup_fatal_logger(layout)
      fatal_logger           = Logging.logger['fatal']
      fatal_logger.level     = 'fatal'
      fatal_logger.appenders = [::Logging.appenders.stderr(:layout => layout)]
      self.loggers << fatal_logger
    end

    def self.setup
      begin
        FileUtils.mkdir_p(KafoConfigure.config.app[:log_dir], :mode => 0750)
      rescue Errno::EACCES
        puts "No permissions to create log dir #{KafoConfigure.config.app[:log_dir]}"
      end

      logger   = Logging.logger['main']
      filename = KafoConfigure.config.log_file
      begin
        logger.appenders = ::Logging.appenders.rolling_file('configure',
                                                            :filename => filename,
                                                            :layout   => NOCOLOR_LAYOUT,
                                                            :truncate => true
        )
        # set owner and group (it's ignored if attribute is nil)
        FileUtils.chown KafoConfigure.config.app[:log_owner], KafoConfigure.config.app[:log_group], filename
      rescue ArgumentError
        puts "File #{filename} not writeable, won't log anything to file!"
      end

      logger.level = KafoConfigure.config.app[:log_level]
      self.loggers << logger

      setup_fatal_logger(color_layout) unless loggers.detect {|l| l.name == 'verbose'}
    end

    def self.setup_verbose
      logger           = Logging.logger['verbose']
      logger.level     = (KafoConfigure.config && KafoConfigure.config.app[:verbose_log_level]) || :info
      layout           = color_layout
      logger.appenders = [::Logging.appenders.stdout(:layout => layout)]
      self.loggers<< logger
    end

    def self.buffering?
      KafoConfigure.verbose.nil? || ((KafoConfigure.verbose && !loggers.detect {|l| l.name == 'verbose'}) || self.loggers.empty?)
    end

    def self.dump_needed?
      !self.buffer.empty?
    end

    def self.to_buffer(buffer, *args)
      buffer << args
    end

    def self.dump_errors
      setup_fatal_logger(color_layout) if loggers.empty?
      unless self.error_buffer.empty?
        loggers.each { |logger| logger.error 'Errors encountered during run:' }
        self.dump_buffer(self.error_buffer)
      end
    end

    def dump_errors
      self.class.dump_errors
    end

    def self.dump_buffer(buffer)
      buffer.each do |log|
        self.loggers.each { |logger| logger.send log[0], *([log[1]].flatten(1)), &log[2] }
      end
      buffer.clear
    end

    def self.color_layout
      KafoConfigure.use_colors? ? COLOR_LAYOUT : NOCOLOR_LAYOUT
    end

    def log(name, *args, &block)
      if self.class.buffering?
        self.class.to_buffer(self.class.buffer, name, args, &block)
      else
        self.class.dump_buffer(self.class.buffer) if self.class.dump_needed?
        self.class.loggers.each { |logger| logger.send name, *args, &block }
      end
    end

    %w(warn info debug).each do |name|
      define_method(name) do |*args, &block|
        self.log(name, *args, &block)
      end
    end

    %w(fatal error).each do |name|
      define_method(name) do |*args, &block|
        self.class.to_buffer(self.class.error_buffer, name, *args, &block)
        self.log(name, *args, &block)
      end
    end
  end
end
