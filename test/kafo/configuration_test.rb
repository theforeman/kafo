require 'test_helper'
require 'yaml'

module Kafo
  describe Configuration do
    let(:basic_config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
    let(:basic_config) { Kafo::Configuration.new(basic_config_file, false) }
    let(:old_config) { Kafo::Configuration.new(basic_config_file, false) }
    let(:current_dir) { File.expand_path('.') }

    let(:p_foo) { fake_param('mod', 'foo', 1) }
    let(:p_bar) { fake_param('mod', 'bar', 10) }
    let(:p_baz) { fake_param('mod', 'baz', 100) }
    let(:p_old_foo) { fake_param('mod', 'foo', 2) }
    let(:p_old_bar) { fake_param('mod', 'bar', 10) }
    let(:p_old_baz) { fake_param('mod', 'baz', 100) }

    specify { basic_config.root_dir.must_equal current_dir }
    specify { basic_config.check_dirs.must_equal [File.join(current_dir, 'checks')] }
    specify { File.exist?(File.expand_path(basic_config.gem_root)) }
    specify { File.expand_path(basic_config.kafo_modules_dir).must_match %r|/modules$|}
    specify { basic_config.temp_config_file.must_match %r|/tmp/kafo_answers_\d+.yaml|}

    describe '#module_dirs' do
      it 'takes modules_dir' do
        cfg = { :modules_dir => './my_modules', :answer_file => 'test/fixtures/basic_answers.yaml'}
        config_file = ConfigFileFactory.build('modules_dir', cfg.to_yaml).path
        config = Kafo::Configuration.new(config_file, false)
        assert_equal [File.join(current_dir, 'my_modules')], config.module_dirs
      end

      it 'takes module_dirs' do
        cfg = { :module_dirs => ['./my_modules','./their_modules'] , :answer_file => 'test/fixtures/basic_answers.yaml'}
        config_file = ConfigFileFactory.build('module_dirs', cfg.to_yaml).path
        config = Kafo::Configuration.new(config_file, false)
        assert_equal [File.join(current_dir, 'my_modules'), File.join(current_dir, 'their_modules')], config.module_dirs
      end
    end

    describe '#params_changed' do
      it 'lists all the params that changed value' do
        basic_config.stub(:params, [p_foo, p_bar, p_baz]) do
          old_config.stub(:params, [p_old_foo, p_old_bar]) do
            basic_config.params_changed(old_config).must_equal([p_foo])
          end
        end
      end
    end

    describe '#params_missing' do
      it 'lists all the params that are missing in the new config' do
        basic_config.stub(:params, [p_foo, p_bar]) do
          basic_config.stub(:module_enabled?, true) do
            old_config.stub(:params, [p_old_foo, p_old_baz]) do
              basic_config.params_missing(old_config).must_equal([p_old_baz])
            end
          end
        end
      end
    end

    describe '#preset_defaults_from_other_config' do
      it 'merges values from the other config' do
        basic_config.stub(:params, [p_foo, p_bar]) do
          old_config.stub(:params, [p_old_foo, p_old_bar, p_old_baz]) do
            basic_config.preset_defaults_from_other_config(old_config)
            basic_config.param('mod', 'foo').value.must_equal 2
            basic_config.param('mod', 'bar').value.must_equal 10
            basic_config.param('mod', 'baz').must_be_nil
          end
        end
      end
    end

    describe '#migrate_configuration' do

      let(:keys) { [:log_dir, :log_name, :log_level, :no_prefix, :default_values_dir,
          :colors, :color_of_background, :custom, :password, :verbose_log_level] }

      before do
        (keys + [:description]).each { |key| old_config.app[key] = 'old value' }
      end

      it 'migrates values from other configuration' do
        basic_config.migrate_configuration(old_config)
        keys.each { |key| basic_config.app[key].must_equal 'old value' }
        basic_config.app[:description].wont_equal 'old value'
      end

      it 'migrates values from other configuration except those marked to skip' do
        basic_config.migrate_configuration(old_config, :skip => [:log_name])
        basic_config.app[:log_name].wont_equal 'old value'
      end

      it 'migrates values from other configuration plus those marked to add' do
        basic_config.migrate_configuration(old_config, :with => [:description])
        basic_config.app[:description].must_equal 'old value'
      end
    end
  end
end
