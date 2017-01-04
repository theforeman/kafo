# encoding: UTF-8
module Kafo
  class PuppetCommand
    def initialize(command, options = [], puppet_config = nil, configuration = KafoConfigure.config)
      @configuration = configuration
      @command = command
      @puppet_config = puppet_config

      # Expand the modules_path to work around the fact that Puppet doesn't
      # allow modulepath to contain relative (i.e ..) directory references as
      # of 2.7.23.
      @options = options.push("--modulepath #{File.expand_path(modules_path)}")
      @options.push("--config=#{puppet_config.config_path}") if puppet_config
      @logger  = KafoConfigure.logger
    end

    def add_progress
      %{$kafo_add_progress="#{!KafoConfigure.verbose}"}
    end

    def command
      @puppet_config.write_config if @puppet_config
      result = [
          "echo '$kafo_config_file=\"#{@configuration.config_file}\" #{add_progress} #{@command}'",
          '|',
          "RUBYLIB=#{[@configuration.kafo_modules_dir, ::ENV['RUBYLIB']].join(File::PATH_SEPARATOR)}",
          "#{puppet_path} apply #{@options.join(' ')} #{@suffix}",
      ].join(' ')
      @logger.debug result
      result
    end

    def append(suffix)
      @suffix = suffix
      self
    end

    def self.search_puppet_path(bin_name)
      bin_path = (::ENV['PATH'].split(File::PATH_SEPARATOR) + ['/opt/puppetlabs/bin']).find do |path|
        File.executable?(File.join(path, bin_name))
      end
      File.join([bin_path, bin_name].compact)
    end

    private

    def modules_path
      [
          @configuration.module_dirs,
          @configuration.kafo_modules_dir,
      ].flatten.join(':')
    end

    def puppet_path
      @puppet_path ||= self.class.search_puppet_path('puppet')
    end
  end
end
