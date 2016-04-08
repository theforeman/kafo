# encoding: UTF-8
module Kafo
  class PuppetCommand
    def initialize(command, options = [], configuration = KafoConfigure.config)
      @configuration = configuration
      @command = command

      # Expand the modules_path to work around the fact that Puppet doesn't
      # allow modulepath to contain relative (i.e ..) directory references as
      # of 2.7.23.
      @options = options.push("--modulepath #{File.expand_path(modules_path)}")
      @logger  = KafoConfigure.logger
    end

    def custom_answer_file
      KafoConfigure.temp_config_file.nil? ? '' : "$kafo_answer_file=\"#{KafoConfigure.temp_config_file}\""
    end

    def add_progress
      KafoConfigure.verbose ? '' : "$kafo_add_progress=true"
    end

    def command
      result = [
          "echo '$kafo_config_file=\"#{@configuration.config_file}\" #{custom_answer_file} #{add_progress} #{@command}'",
          '|',
          "RUBYLIB=#{["#{@configuration.gem_root}/modules", ::ENV['RUBYLIB']].join(File::PATH_SEPARATOR)}",
          "#{puppet_path} apply #{@options.join(' ')} #{@suffix}",
      ].join(' ')
      @logger.debug result
      result
    end

    def append(suffix)
      @suffix = suffix
      self
    end

    private

    def modules_path
      [
          @configuration.module_dirs,
          @configuration.kafo_modules_dir,
      ].flatten.join(':')
    end

    def puppet_path
      @puppet_path ||= begin
        bin_name = 'puppet'
        bin_path = (::ENV['PATH'].split(File::PATH_SEPARATOR) + ['/opt/puppetlabs/bin']).find do |path|
          File.executable?(File.join(path, bin_name))
        end
        File.join([bin_path, bin_name].compact)
      end
    end
  end
end
