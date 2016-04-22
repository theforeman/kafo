module Kafo
  class MigrationContext

    attr_accessor :scenario, :answers

    def self.execute(scenario, answers, &migration)
      context = new(scenario, answers)
      context.instance_eval(&migration)
      return context.scenario, context.answers
    end

    def initialize(scenario, answers)
      @scenario = scenario
      @answers = answers
    end

    def logger
      KafoConfigure.logger
    end

    def facts
      self.class.facts
    end

    private

    def self.facts
      @facts ||= begin
        YAML.load(`#{facter_path} --yaml`).inject({}) { |facts,(k,v)| facts.update(k.to_sym => v) }
      end
    end

    def self.facter_path
      @facter_path ||= PuppetCommand.search_puppet_path('facter')
    end
  end
end
