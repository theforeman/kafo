require 'kafo/base_context'

module Kafo
  class MigrationContext < BaseContext

    attr_accessor :migration_name, :scenario, :answers

    def self.execute(migration_name, scenario, answers, &migration)
      context = new(migration_name, scenario, answers)
      context.instance_eval(&migration)
      return context.scenario, context.answers, context.keep_migration?
    end

    def initialize(migration_name, scenario, answers)
      @migration_name = migration_name
      @scenario = scenario
      @answers = answers
    end

    def self.logger
      # Allows us to defer initializing logger or updating its name
      # until MigrationContext.logger is called. This is useful
      # because most migrations do not log internal state.
      logger ||= Kafo::Logger.new(self.migration_name)
      logger.name = migration_name if (logger.name != migration_name)
      logger
    end

    def self.migration_name
      @migration_name
    end

    def self.keep_migration?
      keep_migration?
    end

    def self.keep_migration
      logger.debug "Migration #{migration_name} has been marked for keeping. "\
      "It may update configuration and answers, but it will not be written to "\
      "applied migrations."
      @keep_migration = true
    end

    private

    def logger
      @logger
    end

    def keep_migration?
      !!@keep_migration
    end
  end
end
