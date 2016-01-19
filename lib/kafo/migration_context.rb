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
  end
end
