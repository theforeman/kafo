require 'acceptance/test_helper'

module Kafo
  describe 'kafo-export-params' do
    describe '--help' do
      before do
        generate_installer
        add_manifest
      end

      it 'outputs usage' do
        code, out, _ = run_command('kafo-export-params --help')
        _(code).must_equal 0
        _(out).must_include 'Usage:'
        _(out).must_include 'kafo-export-params [OPTIONS]'
      end
    end

    describe 'md format' do
      before do
        generate_installer
        add_manifest
      end

      it 'outputs markdown' do
        code, out, _ = run_command "kafo-export-params -f md -c #{KAFO_CONFIG}"
        _(code).must_equal 0
        _(out).must_match(/\| Parameter name\s*\| Description\s*\|/)
        _(out).must_match(/\| --testing-db-type\s*\| can be mysql or sqlite\s*\|/)
      end
    end

    describe '-f' do
      before do
        generate_installer
        add_manifest
      end

      let(:command) { run_command "kafo-export-params -f #{format} -c #{KAFO_CONFIG}" }

      describe 'md' do
        let(:format) { 'md' }
        it 'must output markdown' do
          _(command[1]).must_match(/\| Parameter name\s*\| Description\s*\|/)
          _(command[1]).must_match(/\| --testing-db-type\s*\| can be mysql or sqlite\s*\|/)
        end
      end

      describe 'html' do
        let(:format) { 'html' }
        it 'must output HTML' do
          _(command[1]).must_include '<th>Option</th>'
          _(command[1]).must_match %r{<td.*>--testing-db-type</td>}
          _(command[1]).must_include '<td>can be mysql or sqlite</td>'
        end
      end

      describe 'asciidoc' do
        let(:format) { 'asciidoc' }
        it 'must output asciidoc' do
          _(command[1]).must_include "Parameters for 'testing':"
          _(command[1]).must_include '--testing-db-type'
          _(command[1]).must_include 'can be mysql or sqlite'
        end
      end

      describe 'parsercache' do
        let(:format) { 'parsercache' }
        it 'must output parser cache JSON' do
          _(command[1]).must_include 'version: 1'
          _(command[1]).must_include 'testing:'
          _(command[1]).must_include 'db_type:'
          _(command[1]).must_include 'can be mysql or sqlite'
        end
      end
    end

    describe 'with parser cache' do
      before do
        generate_installer
        add_manifest
        File.open(KAFO_CONFIG, 'a') { |f| f.puts ":parser_cache_path: #{INSTALLER_HOME}/parser_cache.json" }
      end

      it 'writes and reads cache' do
        code, out, err = run_command("kafo-export-params -f parsercache -c #{KAFO_CONFIG} -o #{INSTALLER_HOME}/parser_cache.json")
        _(code).must_equal 0
        _(err).must_include 'Using Puppet module parser'
        _(File.size?("#{INSTALLER_HOME}/parser_cache.json")).wont_be_nil

        code, out, err = run_command("kafo-export-params -f asciidoc -c #{KAFO_CONFIG}")
        _(code).must_equal 0
        _(err).must_include "Using #{INSTALLER_HOME}/parser_cache.json cache with parsed modules"
        _(out).must_include "Parameters for 'testing':"
        _(out).must_include "--testing-db-type"
      end

      it 'forces cache with --parser-cache' do
        code, _, err = run_command("kafo-export-params -f parsercache -c #{KAFO_CONFIG} -o #{INSTALLER_HOME}/parser_cache.json")
        _(code).must_equal 0
        _(File.size?("#{INSTALLER_HOME}/parser_cache.json")).wont_be_nil
        FileUtils.touch(File.join(MANIFEST_PATH, 'init.pp'), :mtime => Time.now + 3600)

        code, _, err = run_command("kafo-export-params --parser-cache -f asciidoc -c #{KAFO_CONFIG}")
        _(code).must_equal 0
        _(err).must_include "Parser cache for #{MANIFEST_PATH}/init.pp is outdated, forced to use it anyway"
      end

      it 'forces off cache with --no-parser-cache' do
        code, _, err = run_command("kafo-export-params -f parsercache -c #{KAFO_CONFIG} -o #{INSTALLER_HOME}/parser_cache.json")
        _(code).must_equal 0
        _(File.size?("#{INSTALLER_HOME}/parser_cache.json")).wont_be_nil

        code, _, err = run_command("kafo-export-params --no-parser-cache -f asciidoc -c #{KAFO_CONFIG}")
        _(code).must_equal 0
        _(err).must_include "Skipping parser cache for #{MANIFEST_PATH}/init.pp, forced off"
      end
    end
  end
end
