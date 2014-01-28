# encoding: UTF-8
require 'fileutils'
require 'logging'

module Kafo
  class Logger
    class << self
      attr_accessor :loggers
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

    def self.setup
      begin
        FileUtils.mkdir_p(KafoConfigure.config.app[:log_dir], :mode => 0750)
      rescue Errno::EACCES => e
        puts "No permissions to create log dir #{KafoConfigure.config.app[:log_dir]}"
      end

      logger   = Logging.logger['main']
      filename = "#{KafoConfigure.config.app[:log_dir]}/#{KafoConfigure.config.app[:log_name] || 'configure.log'}"
      begin
        logger.appenders = ::Logging.appenders.rolling_file('configure',
                                                            :filename => filename,
                                                            :layout   => NOCOLOR_LAYOUT,
                                                            :truncate => true
        )
        # set owner and group (it's ignored if attribute is nil)
        FileUtils.chown KafoConfigure.config.app[:log_owner], KafoConfigure.config.app[:log_group], filename
      rescue ArgumentError => e
        puts "File #{filename} not writeable, won't log anything to file!"
      end

      logger.level = KafoConfigure.config.app[:log_level]

      fatal_logger           = Logging.logger['fatal']
      fatal_logger.level     = 'fatal'
      layout                 = KafoConfigure.config.app[:colors] ? COLOR_LAYOUT : NOCOLOR_LAYOUT
      fatal_logger.appenders = [::Logging.appenders.stderr(:layout => layout)]
      
      self.loggers = [logger, fatal_logger]
    end

    def self.setup_verbose
      logger           = Logging.logger['verbose']
      logger.level     = KafoConfigure.config.app[:verbose_log_level]
      layout           = KafoConfigure.config.app[:colors] ? COLOR_LAYOUT : NOCOLOR_LAYOUT
      logger.appenders = [::Logging.appenders.stdout(:layout => layout)]
      self.loggers<< logger
    end

    %w(fatal error warn info debug).each do |name|
      define_method(name) do |*args, &block|
        self.class.loggers.each { |logger| logger.send name, *args, &block }
      end
    end
  end
end
