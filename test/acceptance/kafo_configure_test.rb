require 'acceptance/test_helper'

module Kafo
  describe 'kafo-configure' do
    before do
      generate_installer
      add_manifest
    end

    describe '--help' do
      it 'includes usage and basic params' do
        code, out, err = run_command 'bin/kafo-configure --help'
        code.must_equal 0, err
        out.must_include "Usage:"
        out.must_include "kafo-configure [OPTIONS]"
        out.must_match(/--testing-version\s*some version number \(current: "1.0"\)/)
        out.wont_include "--testing-db-type"
        out.wont_include "--reset-"
        out.must_include "Use --full-help to view the complete list."
      end
    end

    describe '--full-help' do
      it 'includes all params' do
        code, out, err = run_command 'bin/kafo-configure --full-help'
        code.must_equal 0, err
        out.must_include "Usage:"
        out.must_include "kafo-configure [OPTIONS]"
        out.must_include "== Basic:"
        out.must_match(/--testing-version\s*some version number \(current: "1.0"\)/)
        out.must_match(/--reset-testing-version\s*Reset version to the default value \("1.0"\)/)
        out.must_include "== Advanced:"
        out.must_match(/--testing-db-type\s*can be mysql or sqlite \(current: "mysql"\)/)
        out.must_match(/--reset-testing-db-type\s*Reset db_type to the default value \("mysql"\)/)
        out.wont_include "Use --full-help to view the complete list."
      end
    end

    describe 'default args' do
      it 'must create file' do
        code, _, err = run_command 'bin/kafo-configure'
        code.must_equal 0, err
        File.exist?("#{INSTALLER_HOME}/testing").must_equal true
        File.read("#{INSTALLER_HOME}/testing").must_equal '1.0'
      end

      it 'must fail if validations fail' do
        code, _, err = run_command 'bin/kafo-configure --testing-pool-size=fail'
        code.exitstatus.must_equal 21, err
        err.must_include 'Parameter testing-pool-size invalid: "fail" is not a valid integer'
        File.exist?("#{INSTALLER_HOME}/testing").must_equal false
      end

      it 'must fail if system checks fail' do
        FileUtils.mkdir "#{INSTALLER_HOME}/checks"
        FileUtils.cp File.expand_path('../../fixtures/checks/fail/fail.sh', __FILE__), "#{INSTALLER_HOME}/checks"
        code, _, err = run_command 'bin/kafo-configure'
        code.exitstatus.must_equal 20, err
        File.exist?("#{INSTALLER_HOME}/testing").must_equal false
      end
    end

    describe '--noop' do
      it 'must not create file' do
        code, _, err = run_command 'bin/kafo-configure -n'
        code.must_equal 0, err
        File.exist?("#{INSTALLER_HOME}/testing").must_equal false
      end
    end

    describe 'with parameter argument' do
      it 'must apply and persist value' do
        code, _, err = run_command 'bin/kafo-configure --testing-version 2.0'
        code.must_equal 0, err
        File.read("#{INSTALLER_HOME}/testing").must_equal '2.0'

        code, _, err = run_command 'bin/kafo-configure'
        code.must_equal 0, err
        File.read("#{INSTALLER_HOME}/testing").must_equal '2.0'
      end

      describe 'with no-op' do
        it 'must apply but not persist value' do
          File.open("#{INSTALLER_HOME}/testing", 'w') { |f| f.write('3.0') }

          code, out, err = run_command 'bin/kafo-configure -n -v --testing-version 2.0'
          code.must_equal 0, err
          out.must_match %r{#{Regexp.escape(INSTALLER_HOME)}/testing.*content}
          File.read("#{INSTALLER_HOME}/testing").must_equal '3.0'

          code, out, _ = run_command 'bin/kafo-configure'
          code.must_equal 0
          File.read("#{INSTALLER_HOME}/testing").must_equal '1.0'
        end
      end
    end

    describe 'with parser cache' do
      before do
        File.open(KAFO_CONFIG, 'a') { |f| f.puts ":parser_cache_path: #{INSTALLER_HOME}/parser_cache.json" }
        code, _, err = run_command("kafo-export-params -f parsercache -c #{KAFO_CONFIG} -o #{INSTALLER_HOME}/parser_cache.json")
        code.must_equal 0, err
      end

      it 'must use cache' do
        code, out, err = run_command 'bin/kafo-configure -v -l debug'
        code.must_equal 0, err
        out.must_include "Using #{INSTALLER_HOME}/parser_cache.json cache with parsed modules"
      end

      it 'with --parser-cache forces use of cache' do
        FileUtils.touch(File.join(MANIFEST_PATH, 'init.pp'), :mtime => Time.now + 3600)
        code, out, err = run_command 'bin/kafo-configure -v -l debug --parser-cache'
        code.must_equal 0, err
        out.must_include "Parser cache for #{MANIFEST_PATH}/init.pp is outdated, forced to use it anyway"
      end

      it 'with --no-parser-cache skips cache' do
        FileUtils.touch(File.join(MANIFEST_PATH, 'init.pp'), :mtime => Time.now + 3600)
        code, out, err = run_command 'bin/kafo-configure -v -l debug --no-parser-cache'
        code.must_equal 0, err
        out.must_include "Skipping parser cache for #{MANIFEST_PATH}/init.pp, forced off"
      end
    end

    describe 'with module data' do
      before do
        add_manifest('basic_module_data')
        add_module_data
      end

      it 'must create file' do
        code, _, err = run_command 'bin/kafo-configure'
        code.must_equal 0, err
        File.exist?("#{INSTALLER_HOME}/testing").must_equal true
        File.read("#{INSTALLER_HOME}/testing").must_equal '1.0'
      end
    end

    describe 'with Puppet version requirements' do
      it 'must run if they are met' do
        add_metadata('basic')
        code, _, err = run_command 'bin/kafo-configure'
        code.exitstatus.must_equal 0, err
        File.exist?("#{INSTALLER_HOME}/testing").must_equal true
      end

      it 'must fail if minimum version is not met' do
        add_metadata('with_minimum_puppet')
        code, out, err = run_command 'bin/kafo-configure'
        code.exitstatus.must_equal 30, err
        out.must_match(/^Puppet [0-9\.]+ does not meet (\w+ )?requirements? for theforeman-testing/)
        out.must_include 'Use --skip-puppet-version-check to disable this check'
        File.exist?("#{INSTALLER_HOME}/testing").must_equal false
      end

      it 'must fail if maximum version is not met' do
        add_metadata('with_maximum_puppet')
        code, out, err = run_command 'bin/kafo-configure'
        code.exitstatus.must_equal 30, err
        out.must_match(/^Puppet [0-9\.]+ does not meet (\w+ )?requirements? for theforeman-testing/)
        out.must_include 'Use --skip-puppet-version-check to disable this check'
        File.exist?("#{INSTALLER_HOME}/testing").must_equal false
      end

      it 'must run with --skip-puppet-version-check' do
        add_metadata('with_maximum_puppet')
        code, _, err = run_command 'bin/kafo-configure --skip-puppet-version-check'
        code.exitstatus.must_equal 0, err
        File.exist?("#{INSTALLER_HOME}/testing").must_equal true
      end
    end
  end
end
