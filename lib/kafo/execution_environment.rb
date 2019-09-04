require 'tmpdir'

require 'kafo/hiera_configurer'
require 'kafo/puppet_configurer'

module Kafo
  class ExecutionEnvironment
    def initialize(config, logger = KafoConfigure.logger)
      @config = config
      @logger = logger
    end

    def directory
      @directory ||= begin
        directory = Dir.mktmpdir('kafo_installation')
        @logger.debug("Creating execution environment in #{directory}")
        @hiera_config_path = File.join(directory, 'hiera.conf')
        directory
      end
    end

    def store_answers
      hiera = HieraConfigurer.new(@config.app[:hiera_config], @config.modules, @config.app[:order], directory)
      @hiera_config_path = hiera.write_configs
    end

    def configure_puppet(settings = {})
      @logger.debug("Configuring Puppet in #{directory}")

      settings = {
        'environmentpath' => environmentpath,
        'hiera_config'    => @hiera_config_path,
      }.merge(settings)

      PuppetConfigurer.new(puppet_conf, settings)
    end

    private

    def environmentpath
      File.join(directory, 'environments')
    end

    def puppet_conf
      File.join(directory, 'puppet.conf')
    end
  end
end
