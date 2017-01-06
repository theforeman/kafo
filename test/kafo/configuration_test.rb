require 'test_helper'
require 'yaml'

module Kafo
  describe Configuration do
    let(:basic_config_file) { ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path }
    let(:basic_config) { Kafo::Configuration.new(basic_config_file, false) }
    let(:old_config) { Kafo::Configuration.new(basic_config_file, false) }
    let(:current_dir) { File.expand_path('.') }

    let(:p_foo) { fake_param('foo', 1) }
    let(:p_bar) { fake_param('bar', 10) }
    let(:p_baz) { fake_param('baz', 100) }
    let(:p_old_foo) { fake_param('foo', 2) }
    let(:p_old_bar) { fake_param('bar', 10) }
    let(:p_old_baz) { fake_param('baz', 100) }

    specify { basic_config.root_dir.must_equal current_dir }
    specify { basic_config.check_dirs.must_equal [File.join(current_dir, 'checks')] }
    specify { File.exist?(File.expand_path(basic_config.gem_root)) }
    specify { File.expand_path(basic_config.kafo_modules_dir).must_match %r|/modules$|}

    describe '#log_exists?' do
      it 'returns true if a non-empty log file exists for the configuration' do
        Dir.mktmpdir do |log_dir|
          cfg = { :modules_dir => './my_modules',
                  :answer_file => 'test/fixtures/basic_answers.yaml',
                  :log_dir => log_dir }
          config_file = ConfigFileFactory.build('modules_dir', cfg.to_yaml).path
          config = Kafo::Configuration.new(config_file, false)
          refute config.log_exists?
          File.open(config.log_file, 'w') { |f| f.write 'non-empty-log' }
          assert config.log_exists?
          File.open(config.log_file, 'w') { |f| f.write '' }
          refute config.log_exists?
          old_log = config.log_file.sub(/\.log\Z/) { |suffix| ".1#{ suffix }"}
          File.open(old_log, 'w') { |f| f.write('old-non-empty-log') }
          assert config.log_exists?
        end
      end
    end

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
        basic_config.stub(:modules, [fake_module('mod', [p_foo, p_bar, p_baz])]) do
          old_config.stub(:modules, [fake_module('mod', [p_old_foo, p_old_bar, p_old_baz])]) do
            basic_config.params_changed(old_config).must_equal([p_foo])
          end
        end
      end
    end

    describe '#params_missing' do
      it 'lists all the params that are missing in the new config' do
        basic_config.stub(:modules, [fake_module('mod', [p_foo, p_bar])]) do
          basic_config.stub(:module_enabled?, true) do
            old_config.stub(:modules, [fake_module('mod', [p_old_foo, p_old_baz])]) do
              basic_config.params_missing(old_config).must_equal([p_old_baz])
            end
          end
        end
      end
    end

    describe '#preset_defaults_from_other_config' do
      it 'merges values from the other config' do
        basic_config.stub(:modules, [fake_module('mod', [p_foo, p_bar])]) do
          old_config.stub(:modules, [fake_module('mod', [p_old_foo, p_old_bar, p_old_baz])]) do
            basic_config.preset_defaults_from_other_config(old_config)
            basic_config.param('mod', 'foo').value.must_equal 2
            basic_config.param('mod', 'bar').value.must_equal 10
            basic_config.param('mod', 'baz').must_be_nil
          end
        end
      end
    end

    describe '#migrate_configuration' do

      let(:keys) { [:log_dir, :log_name, :log_level, :no_prefix,
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

    describe '#run_migrations' do
      before do
        @tmp_dir = Dir.mktmpdir
        File.open("#{@tmp_dir}/01.rb", 'w') {|f| f.write("scenario[:custom][:test] = '01'") }
        File.open("#{@tmp_dir}/02.rb", 'w') {|f| f.write("scenario[:description] = 'Migrated'") }
      end

      after do
        FileUtils.rm_rf( @tmp_dir ) if File.exists?( @tmp_dir )
      end

      it "runs the migrations" do
        basic_config.stub(:migrations_dir, @tmp_dir) do
          basic_config.run_migrations
          basic_config.app[:description].must_equal 'Migrated'
          basic_config.app[:custom].must_equal({ :test => '01'})
        end
      end

      it "wont run the applied migrations twice" do
        basic_config.stub(:migrations_dir, @tmp_dir) do
          basic_config.run_migrations
          YAML.load_file(File.join(@tmp_dir, '.applied')).must_equal ["01.rb", "02.rb"]

          basic_config.app[:description] = "New desc"
          basic_config.run_migrations
          basic_config.app[:description].must_equal "New desc"
        end
      end
    end

    describe '#migrations_dir' do
      specify { basic_config.migrations_dir.must_match /\/tmp\/testing_config.*\.migrations$/ }
    end

    describe '#module' do
      it 'finds module by name' do
        basic_config.stub(:modules, [PuppetModule.new('a', nil), PuppetModule.new('b', nil)]) do
          basic_config.module('b').must_be_kind_of PuppetModule
          basic_config.module('c').must_be_nil
        end
      end
    end

    describe '#param' do
      let(:param) { fake_param('test', 1) }

      it 'finds parameter by name' do
        basic_config.stub(:module, fake_module('mod', [param])) do
          basic_config.param('mod', 'test').must_equal param
          basic_config.param('mod', 'unknown').must_be_nil
          basic_config.param('unknown', 'unknown').must_be_nil
        end
      end

      it 'returns nil for unknown module' do
        basic_config.stub(:module, nil) do
          basic_config.param('unknown', 'unknown').must_be_nil
        end
      end
    end

    describe '#modules' do
      it 'returns array of parsed PuppetModules' do
        mod = MiniTest::Mock.new
        mod.expect(:parse, mod)
        PuppetModule.stub(:new, mod) do
          basic_config.modules.must_equal [mod]
        end
      end

      describe 'with custom data types' do
        after { DataType.unregister_type('Test') }

        it 'finds types' do
          Dir.stub(:[], Proc.new { |glob| ['type.pp'] if glob == File.expand_path('../../fixtures/modules/*/types/**/*.pp', __FILE__) }) do
            File.stub(:read, Proc.new { |path| 'type Test = String' if path == 'type.pp' }) do
              mod = MiniTest::Mock.new
              mod.expect(:parse, mod)
              PuppetModule.stub(:new, mod) do
                basic_config.modules
                DataType.types.must_include 'Test'
                basic_config.modules  # must not register twice
              end
            end
          end
        end
      end
    end
  end
end
