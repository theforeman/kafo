require 'test_helper'

module Kafo
  describe KafoConfigure do
    describe "#colors?" do
      before :all do
        @argv = ARGV
      end

      after :all do
        ARGV.clear
        ARGV.concat(@argv)
      end

      it 'checks config' do
        KafoConfigure.config.app[:colors] = true
        _(KafoConfigure.use_colors?).must_equal true
      end

      it 'checks --colors in ARGV when no config' do
        ARGV << '--colors'
        KafoConfigure.config = nil
        _(KafoConfigure.use_colors?).must_equal true
      end

      it 'checks --no-colors in ARGV when no config' do
        ARGV << '--no-colors'
        KafoConfigure.config = nil
        _(KafoConfigure.use_colors?).must_equal false
      end
    end

    describe '#puppet_report' do

      before { KafoConfigure.puppet_report = report }
      after { KafoConfigure.puppet_report = nil }

      describe 'without a report' do
        let(:report) { nil }

        specify { assert_nil KafoConfigure.puppet_report }
      end

      describe 'with a report' do
        let(:report) { PuppetReport.new({ 'report_format' => 11 }) }

        specify { assert_equal(report, KafoConfigure.puppet_report) }
      end
    end
  end
end
