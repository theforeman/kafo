require 'tempfile'

module Kafo
  class PuppetConfigurer
    attr_reader :logger

    def initialize(settings = {})
      @settings = {'reports' => ''}.merge(settings)
      @logger = KafoConfigure.logger
      @temp_file = Tempfile.new(['kafo_puppet', '.conf'])
    end

    def config_path
      @temp_file.path
    end

    def [](key)
      @settings[key]
    end

    def []=(key, value)
      @settings[key] = value
    end

    def write_config
      @logger.debug("Writing Puppet config file at #{@temp_file.path}")
      @temp_file.open
      @temp_file.truncate(0)
      @temp_file.puts '[main]'
      @settings.keys.sort.each do |key|
        @temp_file.puts "#{key} = #{@settings[key]}"
      end
    ensure
      @temp_file.close
    end
  end
end
