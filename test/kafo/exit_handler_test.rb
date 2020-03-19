require 'test_helper'

module Kafo
  describe ExitHandler do
    let(:handler) { ExitHandler.new }

    describe 'default exit code' do
      specify(:exit_code) { _(handler.exit_code).must_equal 0 }
    end

    describe '#error_codes' do
      it { _(handler.error_codes).must_be_kind_of(Hash) }
    end

    describe '#translate_exit_code' do
      it 'numbers should not change' do
        _(handler.translate_exit_code(0)).must_equal 0
        _(handler.translate_exit_code(1)).must_equal 1
      end

      it 'converts known symbols to numbers' do
        _(handler.translate_exit_code(:invalid_system)).must_equal 20
      end

      it 'fails on unknown symbols' do
        begin
          handler.translate_exit_code(:something_that_does_not_exist)
        rescue RuntimeError => e
          _(e.message).must_equal 'Unknown code something_that_does_not_exist'
        end
      end
    end

    describe '#register_cleanup_path' do
      it 'adds path' do
        handler.register_cleanup_path '/a'
        handler.register_cleanup_path '/b'
        _(handler.cleanup_paths.size).must_equal 2
        _(handler.cleanup_paths).must_include '/a'
        _(handler.cleanup_paths).must_include '/b'
      end
    end

    let(:dummy_logger) { DummyLogger.new }
    before { KafoConfigure.logger = dummy_logger }

    describe '#cleanup' do
      it 'always removes /tmp/default_values.yaml' do
        FileUtils.stub(:rm_rf, true) do
          _(handler.cleanup_paths).must_be_empty
          handler.cleanup
          dummy_logger.rewind
          _(dummy_logger.debug.read).must_include '/tmp/default_values.yaml'
        end
      end

      it 'cleans registered paths' do
        FileUtils.stub(:rm_rf, true) do
          handler.register_cleanup_path '/b/a/c'
          handler.cleanup
          dummy_logger.rewind
          _(dummy_logger.debug.read).must_include '/b/a/c'
          dummy_logger.rewind
          _(dummy_logger.debug.read).must_include '/tmp/default_values.yaml'
        end
      end
    end

    describe '#exit' do
      it 'logs exit code' do
        handler.stub(:cleanup, true) do
          begin
            handler.exit(0)
          rescue SystemExit => e
            dummy_logger.rewind
            _(dummy_logger.debug.read).must_include 'Exit with status code: 0'
            _(e.status).must_equal 0
          end
        end
      end

      it 'runs a block is passed' do
        handler.stub(:cleanup, true) do
          begin
            handler.exit(10) { dummy_logger.error 'block executed' }
          rescue SystemExit => e
            dummy_logger.rewind
            _(dummy_logger.error.read.chomp).must_equal 'block executed'
            _(e.status).must_equal 10
          end
        end
      end

      it 'exits with correct exit code' do
        handler.stub(:cleanup, true) do
          begin
            handler.exit(5)
          rescue SystemExit => e
            _(e.status).must_equal 5
          end
        end
      end
    end
  end
end
