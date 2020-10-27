require 'acceptance/test_helper'

module Kafo
  describe 'kafo-configure' do
    before do
      generate_installer
      add_manifest
      @config_file = "#{INSTALLER_HOME}/config/installer-scenarios.d/default.yaml"
      @answers_file = "#{INSTALLER_HOME}/config/installer-scenarios.d/default-answers.yaml"
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
    end

    describe '--noop' do
      it 'must not create file' do
        code, _, err = run_command '../bin/kafo-configure -n'
        _(code).must_equal 0, err
        _(File.exist?("#{INSTALLER_HOME}/testing")).must_equal false
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

    describe 'with disablable modules' do
      it 'must only --[no-]enabled option for disablable module' do
        config = YAML.load_file(@config_file)
        config[:disablable_modules] = ['testing']
        File.open(@config_file, 'w') do |file|
          file.write(config.to_yaml)
        end

        code, out, err = run_command '../bin/kafo-configure --help --scenario default'
        _(out).must_include '--[no-]enable-testing'
      end

      it 'must show no --enable option for enabled module not on disablable_modules list' do
        config = YAML.load_file(@config_file)
        config[:disablable_modules] = []
        File.open(@config_file, 'w') do |file|
          file.write(config.to_yaml)
        end

        code, out, err = run_command '../bin/kafo-configure --help --scenario default'
        _(out).wont_include '--[no-]enable-testing'
        _(out).wont_include '--enable-testing'
      end

      it 'must show --enable option for disabled module not on disablable_modules list' do
        config = YAML.load_file(@config_file)
        config[:disablable_modules] = []
        File.open(@config_file, 'w') do |file|
          file.write(config.to_yaml)
        end

        answers = YAML.load_file(@answers_file)
        answers['testing::disabled_testing_module'] = false
        File.open(@answers_file, 'w') do |file|
          file.write(answers.to_yaml)
        end

        FileUtils.mkdir_p MANIFEST_PATH
        FileUtils.cp File.expand_path("../../fixtures/manifests/disabled_testing_module.pp", __FILE__), File.join(MANIFEST_PATH, 'disabled_testing_module.pp')

        code, out, err = run_command '../bin/kafo-configure --help'
        _(out).must_include '--enable-testing-disabled-testing-module'
      end
    end
  end
end
