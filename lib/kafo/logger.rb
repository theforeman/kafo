# encoding: UTF-8
require 'fileutils'
require 'logging'

class Logger
  pattern        = "[%5l %d %c] %m\n"
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
  COLOR_LAYOUT   = Logging::Layouts::Pattern.new(:pattern => pattern, :color_scheme => 'bright')
  NOCOLOR_LAYOUT = Logging::Layouts::Pattern.new(:pattern => pattern, :color_scheme => nil)

  def self.setup
    begin
      FileUtils.mkdir_p(KafoConfigure.config.app[:log_dir], :mode => 0750)
    rescue Errno::EACCES => e
      puts "No permissions to create log dir #{KafoConfigure.config.app[:log_dir]}"
    end

    logger   = Logging.logger.root
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
  end
end
