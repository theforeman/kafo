# encoding: UTF-8

require 'fileutils'
require 'logging'

module Kafo
  class Logging

    PATTERN = "[%5l %d %c] %m\n"
    ::Logging.color_scheme(
      'bright',
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
    COLOR_LAYOUT = ::Logging::Layouts::Pattern.new(:pattern => PATTERN, :color_scheme => 'bright')
    NOCOLOR_LAYOUT = ::Logging::Layouts::Pattern.new(:pattern => PATTERN, :color_scheme => nil)

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

      def setup
        begin
          FileUtils.mkdir_p(KafoConfigure.config.app[:log_dir], :mode => 0750)
        rescue Errno::EACCES
          puts "No permissions to create log dir #{KafoConfigure.config.app[:log_dir]}"
        end

        logger = ::Logging.logger['main']
        filename = KafoConfigure.config.log_file

        begin
          logger.appenders = ::Logging.appenders.rolling_file(
            'configure',
            :filename => filename,
            :layout   => NOCOLOR_LAYOUT,
            :truncate => true
          )

          FileUtils.chown(
            KafoConfigure.config.app[:log_owner],
            KafoConfigure.config.app[:log_group],
            filename
          )
        rescue ArgumentError
          puts "File #{filename} not writeable, won't log anything to file!"
        end

        logger.level = KafoConfigure.config.app[:log_level]
        loggers << logger
      end

      def setup_verbose
        logger = ::Logging.logger['verbose']
        logger.level = (KafoConfigure.config && KafoConfigure.config.app[:verbose_log_level]) || :info
        logger.appenders = [::Logging.appenders.stdout(:layout => color_layout)]
        loggers << logger
      end

      def buffering?
        KafoConfigure.verbose.nil? || ((KafoConfigure.verbose && !loggers.detect {|l| l.name == 'verbose'}) || loggers.empty?)
      end

      def dump_needed?
        !buffer.empty?
      end

      def to_buffer(buffer, *args)
        buffer << args
      end

      def dump_errors
        unless error_buffer.empty?
          loggers.each { |logger| logger.error 'Errors encountered during run:' }
          dump_buffer(error_buffer)
        end
      end

      def dump_buffer(buffer)
        buffer.each do |log|
          loggers.each { |logger| logger.send log[0], *([log[1]].flatten(1)), &log[2] }
        end
        buffer.clear
      end

      def color_layout
        KafoConfigure.use_colors? ? COLOR_LAYOUT : NOCOLOR_LAYOUT
      end
    end

  end
end
