require 'test_helper'

module Kafo
  describe Migrations do
    let(:migrations) { Migrations.new('some_directory') }
    let(:kafo_configure_logger) { DummyLogger.new('KafoConfigureLogger') }
    let(:migration_context) { MigrationContext.new('previous_migration', {}, {}) }

    describe '#run' do

      before do
        KafoConfigure.logger = kafo_configure_logger
        migrations.add_migration('m1') do
          self.logger.error "#{logger.name} - s1"
        end
        migrations.add_migration('m2') do
          self.logger.error "#{logger.name} - s2"
        end
        migrations.run({}, {})
      end

      it 'executes all the migrations and logs to MigrationContext logger' do
        migration_context_logger.rewind
        _(migration_context_logger.error.read).must_match(/.*m1.*s1.*m2.*s2.*/m)
      end

      it 'MigrationContext does not log to KafoConfigure.logger' do
        kafo_configure_logger.rewind
        !_(kafo_configure_logger.error.read).must_match(/.*s1.*s2.*/m)
      end

      it 'knows the applied migrations' do
        _(migrations.applied).must_equal ['m1', 'm2']
      end
    end
  end
end
