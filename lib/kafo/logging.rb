# encoding: UTF-8

require 'fileutils'
require 'logging'

module Kafo
  class Logging

    class << self
      def root_logger
        @root_logger ||= ::Logging.logger.root
      end

      def setup(verbose: false)
        set_color_scheme
        level = KafoConfigure.config.app[:log_level]

        setup_file_logging(
          level,
          KafoConfigure.config.app[:log_dir],
          KafoConfigure.config.app[:log_owner],
          KafoConfigure.config.app[:log_group]
        )
        setup_verbose(level: KafoConfigure.config.app[:verbose_log_level] || level) if verbose
      end

      def setup_file_logging(log_level, log_dir, log_owner, log_group)
        filename = KafoConfigure.config.log_file

        begin
          FileUtils.mkdir_p(log_dir, :mode => 0750)
        rescue Errno::EACCES
          puts "No permissions to create log dir #{log_dir}"
        end

        begin
          root_logger.appenders = ::Logging.appenders.rolling_file(
            'configure',
            :level => log_level,
            :filename => filename,
            :layout => layout(false),
            :truncate => true
          )

          FileUtils.chown(
            log_owner,
            log_group,
            filename
          )
        rescue ArgumentError
          puts "File #{filename} not writeable, won't log anything to file!"
        end
      end

      def set_color_scheme
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
      end

      def layout(color = false)
        ::Logging::Layouts::Pattern.new(
          :pattern => "%d [%-5l] [%c] %m\n",
          :color_scheme => color ? 'bright' : nil,
          :date_pattern => '%Y-%m-%d %H:%M:%S'
        )
      end

      def color_layout
        layout(KafoConfigure.use_colors?)
      end

      def add_logger(name)
        ::Logging.logger[name]
      end

      def setup_verbose(level: :info)
        stdout = ::Logging.appenders.stdout('verbose', :layout => color_layout, :level => level)
        root_logger.add_appenders(stdout)
      end

      def buffer
        @buffer ||= []
      end

      def buffering?
        root_logger.appenders.empty?
      end

      def dump_needed?
        !buffer.empty?
      end

      def to_buffer(*args)
        buffer << args
      end

      def dump_buffer
        @buffer.each do |log|
          ::Logging.logger[log[0]].send(log[1], *([log[2]].flatten(2)), &log[3])
        end
        @buffer.clear
      end
    end

  end
end
