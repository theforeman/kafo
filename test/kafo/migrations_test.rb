require 'test_helper'

module Kafo
  describe Migrations do
    let(:migrations) { Migrations.new('some_directory') }
    let(:dummy_logger) { DummyLogger.new }

    describe '#run' do

      before do
        KafoConfigure.logger = dummy_logger
        migrations.add_migration('no1') { logger.error 's1' }
        migrations.add_migration('no2') { logger.error 's2' }
        migrations.run({}, {})
      end

      it 'executes all the migrations' do
        dummy_logger.rewind
        dummy_logger.error.read.must_match(/.*s1.*s2.*/m)
      end

      it 'knows the applied migrations' do
        migrations.applied.must_equal ['no1', 'no2']
      end
    end
  end
end
