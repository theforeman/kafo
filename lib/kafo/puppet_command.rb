# encoding: UTF-8
module Kafo
  class PuppetCommand
    def initialize(command, options = [], puppet_config = nil, configuration = KafoConfigure.config)
      @configuration = configuration
      @command = command
      @puppet_config = puppet_config

      @options = options.push("--modulepath #{modules_path.join(':')}")
      @options.push("--config=#{puppet_config.config_path}") if puppet_config
      @logger  = KafoConfigure.logger
      @suffix = nil
    end

    def command
      @puppet_config.write_config if @puppet_config
      result = [
          %{echo '#{@command}'},
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
      ].flatten
    end

    def puppet_path
      @puppet_path ||= self.class.search_puppet_path('puppet')
    end
  end
end
