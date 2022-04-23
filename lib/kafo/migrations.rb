require 'yaml'
require 'kafo/migration_context'

module Kafo
  class Migrations

    attr_reader :migrations

    def initialize(migrations_dir)
      @migrations_dir = migrations_dir
      @migrations = {}
      @applied_file = File.join(@migrations_dir, '.applied')
      load_migrations
    end

    def applied
      @applied ||= load_applied
    end

    def load_migrations
      Dir.glob(@migrations_dir + "/*.rb").each do |file|
        next if applied.include?(File.basename(file))
        KafoConfigure.logger.debug "Loading migration #{file}"
        migration = File.read(file)
        migration_block = proc { instance_eval(migration, file, 1) }
        add_migration(file, &migration_block)
      end
    end

    def add_migration(name, &block)
      @migrations[name] = block
    end

    def run(scenario, answers)
      @migrations.keys.sort.each do |filename|
        short_name = File.basename(filename.to_s)
        KafoConfigure.logger.debug "Executing migration: #{scenario[:name]}::#{short_name}"
        migration = @migrations[filename]
        scenario, answers = Kafo::MigrationContext.execute(short_name, scenario, answers, &migration)
        applied << short_name
      end
      return scenario, answers
    end

    def store_applied
      File.open(@applied_file, 'w') { |f| f.write(applied.to_yaml) }
    end

    private

    def load_applied
      File.exist?(@applied_file) ? YAML.load_file(@applied_file) : []
    end
  end
end
