require 'tempfile'

module Kafo
  class PuppetConfigurer
    attr_reader :logger, :config_path

    def initialize(config_path, settings = {})
      @config_path = config_path
      @settings = {'reports' => ''}.merge(settings)
      @logger = KafoConfigure.logger
    end

    def [](key)
      @settings[key]
    end

    def []=(key, value)
      @settings[key] = value
    end

    def write_config
      @logger.debug("Writing Puppet config file at #{config_path}")
      File.open(config_path, 'w') do |file|
        file.puts '[main]'
        @settings.keys.sort.each do |key|
          file.puts "#{key} = #{@settings[key]}"
        end
      end
    end
  end
end
