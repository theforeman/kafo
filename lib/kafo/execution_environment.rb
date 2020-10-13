require 'tmpdir'

require 'kafo/fact_writer'
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
        directory
      end
    end

    def reportdir
      @reportdir ||= File.join(directory, 'reports')
    end

    def reports
      # Reports are stored in $reportdir/$certname/$report
      Dir.glob(File.join(reportdir, '*', '*.*')).sort_by { |path| File.mtime(path) }
    end

    def store_answers
      answer_data = HieraConfigurer.generate_data(@config.modules, @config.app[:order])
      @logger.debug("Writing temporary answers to #{answer_file}")
      File.open(answer_file, 'w') { |f| f.write(YAML.dump(answer_data)) }
    end

    def configure_puppet(settings = {})
      @logger.debug("Configuring Puppet in #{directory}")

      @logger.debug("Writing facts to #{factpath}")
      FactWriter.write_facts(facts, factpath)

      hiera_config = configure_hiera

      settings = {
        'environmentpath' => environmentpath,
        'factpath'        => factpath,
        'hiera_config'    => hiera_config,
        'reports'         => 'store',
        'reportdir'       => reportdir,
      }.merge(settings)

      PuppetConfigurer.new(puppet_conf, settings)
    end

    private

    def environmentpath
      File.join(directory, 'environments')
    end

    def factpath
      File.join(directory, 'facts')
    end

    def answer_file
      File.join(directory, 'answers.yaml')
    end

    def puppet_conf
      File.join(directory, 'puppet.conf')
    end

    def configure_hiera
      if @config.app[:hiera_config]
        File.realpath(@config.app[:hiera_config])
      else
        config_path = File.join(directory, 'hiera.yaml')
        @logger.debug("Writing default hiera config to #{config_path}")
        HieraConfigurer.write_default_config(config_path)
      end
    end

    def facts
      {
        'scenario' => {
          'id' => @config.scenario_id,
          'name' => @config.app[:name],
          'answer_file' => answer_file,
          'custom' => @config.app[:facts],
        },
      }
    end
  end
end
