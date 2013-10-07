# encoding: UTF-8
require 'fileutils'
require 'logging'

class Logger
  class << self
    attr_accessor :loggers
  end

  PATTERN        = "[%5l %d %c] %m\n"
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
    self.loggers = [logger]
  end

  def self.setup_verbose
    logger           = Logging.logger['verbose']
    logger.level     = KafoConfigure.config.app[:verbose_log_level]
    layout           = KafoConfigure.config.app[:colors] ? COLOR_LAYOUT : NOCOLOR_LAYOUT
    logger.appenders = [::Logging.appenders.stdout(:layout => layout)]
    self.loggers<< logger
  end

  # proxy to all loggers we have setup
  def method_missing(*args, &block)
    self.class.loggers.each do |logger|
      logger.send *args, &block
    end
  end

  def respond_to?(*args, &block)
    self.class.loggers.first.respond_to? *args, &block
  end
end
