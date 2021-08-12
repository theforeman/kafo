require 'acceptance/test_helper'

module Kafo
  describe 'kafo-configure' do
    before do
      generate_installer
      add_manifest
    end

    describe '--help' do
      it 'includes usage and basic params' do
        code, out, err = run_command '../bin/kafo-configure --help'
        _(code).must_equal 0, err
        _(out).must_include "Usage:"
        _(out).must_include "kafo-configure [OPTIONS]"
        _(out).must_match(/--testing-version\s*some version number \(current: "1.0"\)/)
        _(out).wont_include "--testing-db-type"
        _(out).wont_include "--reset-"
        _(out).must_include "Use --full-help to view the complete list."
        _(out).must_include "The available levels are ERROR, WARN, NOTICE, INFO, DEBUG. See --full-help for definitions."
        _(out).wont_include "High level information about installer execution and progress."
      end

      it 'does not include log output with verbose mode' do
        code, out, err = run_command '../bin/kafo-configure --help --verbose'
        _(code).must_equal 0, err
        _(out).must_include "Usage:"
        _(out).wont_include "[NOTICE]"
        _(out).wont_include "Executing hooks"
      end
    end

    describe '--full-help' do
      it 'includes all params' do
        code, out, err = run_command '../bin/kafo-configure --full-help'
        _(code).must_equal 0, err
        _(out).must_include "Usage:"
        _(out).must_include "kafo-configure [OPTIONS]"
        _(out).must_include "== Basic:"
        _(out).must_match(/--testing-version\s*some version number \(current: "1.0"\)/)
        _(out).must_match(/--reset-testing-version\s*Reset version to the default value \("1.0"\)/)
        _(out).must_include "== Advanced:"
        _(out).must_match(/--testing-db-type\s*can be mysql or sqlite \(current: "mysql"\)/)
        _(out).must_match(/--reset-testing-db-type\s*Reset db_type to the default value \("mysql"\)/)
        _(out).wont_include "Use --full-help to view the complete list."
        _(out).wont_include "The available levels are ERROR, WARN, NOTICE, INFO, DEBUG. See --full-help for definitions."
        _(out).must_include "High level information about installer execution and progress."
      end

      it 'does not include log output with verbose mode' do
        code, out, err = run_command '../bin/kafo-configure --full-help --verbose'
        _(code).must_equal 0, err
        _(out).must_include "Usage:"
        _(out).wont_include "[NOTICE]"
        _(out).wont_include "Executing hooks"
      end
    end

    describe '--list-scenarios' do
      it 'lists scenarios' do
        code, out, err = run_command '../bin/kafo-configure --list-scenarios --no-colors'
        _(code).must_equal 0, err
        _(out).must_include "Available scenarios"
        _(out).must_include "default (use: --scenario default)"
      end
    end

    describe 'default args' do
      it 'must create file' do
        code, _, err = run_command '../bin/kafo-configure'
        _(code).must_equal 0, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal true
        _(File.read("#{INSTALLER_HOME}/testing")).must_equal '1.0'
      end

      it 'must fail if validations fail' do
        code, _, err = run_command '../bin/kafo-configure --testing-pool-size=fail'
        _(code.exitstatus).must_equal 21, err
        _(err).must_include 'Parameter testing-pool-size invalid: "fail" is not a valid integer'
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal false
      end

      it 'must fail if system checks fail' do
        FileUtils.mkdir "#{INSTALLER_HOME}/checks"
        FileUtils.cp File.expand_path('../../fixtures/checks/fail/fail.sh', __FILE__), "#{INSTALLER_HOME}/checks"
        code, _, err = run_command '../bin/kafo-configure'
        _(code.exitstatus).must_equal 20, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal false
      end

      it 'must default verbose to false' do
        code, _, err = run_command '../bin/kafo-configure'

        _(code).must_equal 0, err
        _(YAML.load_file(KAFO_CONFIG)[:verbose]).must_equal false
      end
    end

    describe '--noop' do
      it 'must not create file' do
        code, _, err = run_command '../bin/kafo-configure -n'
        _(code).must_equal 0, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal false
      end
    end

    describe 'verbose in the config file' do
      it 'must respect verbose true' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:verbose] = true
        File.open(KAFO_CONFIG, "w") { |file| file.write(config.to_yaml) }

        code, stdout, err = run_command '../bin/kafo-configure'

        _(code).must_equal 0, err
        _(stdout).must_include "NOTICE"
        _(YAML.load_file(KAFO_CONFIG)[:verbose]).must_equal true
      end

      it 'must respect verbose false' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:verbose] = false
        File.open(KAFO_CONFIG, "w") { |file| file.write(config.to_yaml) }

        code, stdout, err = run_command '../bin/kafo-configure'

        _(code).must_equal 0, err
        _(stdout).wont_include "NOTICE"
        _(YAML.load_file(KAFO_CONFIG)[:verbose]).must_equal false
      end

      it 'must respect --verbose' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:verbose] = false
        File.open(KAFO_CONFIG, "w") { |file| file.write(config.to_yaml) }

        code, stdout, err = run_command '../bin/kafo-configure --verbose'

        _(code).must_equal 0, err
        _(stdout).must_include "NOTICE"
        _(YAML.load_file(KAFO_CONFIG)[:verbose]).must_equal true
      end

      it 'must respect --no-verbose' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:verbose] = true
        File.open(KAFO_CONFIG, "w") { |file| file.write(config.to_yaml) }

        code, stdout, err = run_command '../bin/kafo-configure --no-verbose'
        updated_config = YAML.load_file(KAFO_CONFIG)

        _(code).must_equal 0, err
        _(stdout).wont_include "NOTICE"
        _(updated_config[:verbose]).must_equal false
      end
    end

    describe 'with parameter argument' do
      it 'must apply and persist value' do
        code, _, err = run_command '../bin/kafo-configure --testing-version 2.0'
        _(code).must_equal 0, err
        _(File.read("#{INSTALLER_HOME}/testing")).must_equal '2.0'

        code, _, err = run_command '../bin/kafo-configure'
        _(code).must_equal 0, err
        _(File.read("#{INSTALLER_HOME}/testing")).must_equal '2.0'
      end

      describe 'with no-op' do
        it 'must apply but not persist value' do
          File.open("#{INSTALLER_HOME}/testing", 'w') { |f| f.write('3.0') }

          code, out, err = run_command '../bin/kafo-configure -n -v -l debug --testing-version 2.0'
          _(code).must_equal 0, err
          _(out).must_match %r{#{Regexp.escape(INSTALLER_HOME)}/testing.*content}
          _(File.read("#{INSTALLER_HOME}/testing")).must_equal '3.0'

          code, out, _ = run_command '../bin/kafo-configure'
          _(code).must_equal 0
          _(File.read("#{INSTALLER_HOME}/testing")).must_equal '1.0'
        end
      end
    end

    describe 'with parser cache' do
      before do
        File.open(KAFO_CONFIG, 'a') do |f|
          f.puts ":parser_cache_path: #{INSTALLER_HOME}/parser_cache.json"
        end

        code, _, err = run_command("kafo-export-params -f parsercache -c #{KAFO_CONFIG} -o #{INSTALLER_HOME}/parser_cache.json")
        _(code).must_equal 0, err
      end

      it 'must use cache' do
        code, out, err = run_command '../bin/kafo-configure -v -l debug'
        _(code).must_equal 0, err
        _(out).must_include "Using #{INSTALLER_HOME}/parser_cache.json cache with parsed modules"
      end

      it 'with --parser-cache forces use of cache' do
        FileUtils.touch(File.join(MANIFEST_PATH, 'init.pp'), :mtime => Time.now + 3600)
        code, out, err = run_command '../bin/kafo-configure -v -l debug --parser-cache'
        _(code).must_equal 0, err
        _(out).must_include "Parser cache for #{MANIFEST_PATH}/init.pp is outdated, forced to use it anyway"
      end

      it 'with --no-parser-cache skips cache' do
        FileUtils.touch(File.join(MANIFEST_PATH, 'init.pp'), :mtime => Time.now + 3600)
        code, out, err = run_command '../bin/kafo-configure -v -l debug --no-parser-cache'
        _(code).must_equal 0, err
        _(out).must_include "Skipping parser cache for #{MANIFEST_PATH}/init.pp, forced off"
      end
    end

    describe 'with module data' do
      before do
        add_manifest('basic_module_data')
        add_module_data
      end

      it 'must create file' do
        code, _, err = run_command '../bin/kafo-configure'
        _(code).must_equal 0, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal true
        _(File.read("#{INSTALLER_HOME}/testing")).must_equal '1.0'
      end
    end

    describe 'with Puppet version requirements' do
      it 'must run if they are met' do
        add_metadata('basic')
        code, _, err = run_command '../bin/kafo-configure'
        _(code.exitstatus).must_equal 0, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal true
      end

      it 'must fail if minimum version is not met' do
        add_metadata('with_minimum_puppet')
        code, out, err = run_command '../bin/kafo-configure'
        _(code.exitstatus).must_equal 30, err
        _(out).must_match(/^Puppet [0-9\.]+ does not meet (\w+ )?requirements? for theforeman-testing/)
        _(out).must_include 'Use --skip-puppet-version-check to disable this check'
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal false
      end

      it 'must fail if maximum version is not met' do
        add_metadata('with_maximum_puppet')
        code, out, err = run_command '../bin/kafo-configure'
        _(code.exitstatus).must_equal 30, err
        _(out).must_match(/^Puppet [0-9\.]+ does not meet (\w+ )?requirements? for theforeman-testing/)
        _(out).must_include 'Use --skip-puppet-version-check to disable this check'
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal false
      end

      it 'must run with --skip-puppet-version-check' do
        add_metadata('with_maximum_puppet')
        code, _, err = run_command '../bin/kafo-configure --skip-puppet-version-check'
        _(code.exitstatus).must_equal 0, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal true
      end
    end

    describe 'the configuration file' do
      before do
        @saved_values = Kafo::Configuration::DEFAULT.reject do |key, value|
          value.nil?
        end
      end

      it 'must only save defined values' do
        code, _, err = run_command '../bin/kafo-configure'

        _(code).must_equal 0, err
        _(YAML.load_file(KAFO_CONFIG).keys.sort).must_equal @saved_values.keys.sort
      end

      it 'must not save command line options when --noop' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:color_of_background] = "bright"
        File.open(KAFO_CONFIG, 'w') do |file|
          file.write(config.to_yaml)
        end

        code, _, err = run_command '../bin/kafo-configure --noop --color-of-background dark'

        _(code).must_equal 0, err
        _(YAML.load_file(KAFO_CONFIG).keys.sort).must_equal @saved_values.keys.sort
        _(YAML.load_file(KAFO_CONFIG).keys).wont_include 'noop'
        _(YAML.load_file(KAFO_CONFIG)[:color_of_background]).must_equal "bright"
      end

      it 'must not save non-persisted command line options' do
        code, _, err = run_command '../bin/kafo-configure --profile'

        _(code).must_equal 0, err
        _(YAML.load_file(KAFO_CONFIG).keys.sort).must_equal @saved_values.keys.sort
        _(YAML.load_file(KAFO_CONFIG).keys).wont_include 'profile'
      end

      it 'must save persisted command line options' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:color_of_background] = "bright"
        File.open(KAFO_CONFIG, 'w') do |file|
          file.write(config.to_yaml)
        end

        code, _, err = run_command '../bin/kafo-configure --color-of-background dark'

        _(code).must_equal 0, err
        _(YAML.load_file(KAFO_CONFIG).keys.sort).must_equal @saved_values.keys.sort
        _(YAML.load_file(KAFO_CONFIG)[:color_of_background]).must_equal "dark"
      end
    end

    describe 'exit codes' do
      it 'exit code should be set before post hooks' do
        code, stdout, err = run_command '../bin/kafo-configure'

        _(stdout).must_include "2"

        code, stdout, err = run_command '../bin/kafo-configure'

        _(stdout).must_include "0"
      end
    end

    describe 'hooks ordering' do
      it 'should execute hooks in globally sorted order' do
        code, stdout, err = run_command '../bin/kafo-configure'

        _(stdout).must_include "Runs before exit code hook in post\n2"
      end
    end

    describe 'multi-stage hooks' do
      it 'should execute multi-stage hooks' do
        code, stdout, err = run_command '../bin/kafo-configure --print-hello-kafo'

        _(stdout).must_include "Hello Kafo\nGoodbye"
      end
    end

    describe 'with classes' do
      it 'includes enable flag by default' do
        code, out, err = run_command '../bin/kafo-configure --help'
        _(code).must_equal 0, err
        _(out).must_include "--[no-]enable-testing"
      end

      it 'does not show disable flag if class cannot be disabled' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:classes] = {:testing => {:can_disable => false}}
        File.open(KAFO_CONFIG, 'w') do |file|
          file.write(config.to_yaml)
        end

        code, out, err = run_command '../bin/kafo-configure --help'
        _(code).must_equal 0, err
        _(out).wont_include "--[no-]enable-testing"
      end

      it 'shows enable flag if class is disabled' do
        config = YAML.load_file(KAFO_CONFIG)
        config[:classes] = {:testing => {:can_disable => false}}
        File.open(KAFO_CONFIG, 'w') do |file|
          file.write(config.to_yaml)
        end

        answers = {'testing' => false}
        File.open(KAFO_ANSWERS, 'w') do |file|
          file.write(answers.to_yaml)
        end

        code, out, err = run_command '../bin/kafo-configure --help'
        _(code).must_equal 0, err
        _(out).must_include "--enable-testing"
      end
    end
  end
end
