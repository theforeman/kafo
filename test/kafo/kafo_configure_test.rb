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
        KafoConfigure.use_colors?.must_equal true
      end

      it 'checks --colors in ARGV when no config' do
        ARGV << '--colors'
        KafoConfigure.config = nil
        KafoConfigure.use_colors?.must_equal true
      end

      it 'checks --no-colors in ARGV when no config' do
        ARGV << '--no-colors'
        KafoConfigure.config = nil
        KafoConfigure.use_colors?.must_equal false
      end
    end
  end
end
