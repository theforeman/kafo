require 'acceptance/test_helper'

module Kafo
  describe 'kafo-export-params' do
    describe '--help' do
      it 'outputs usage' do
        code, out, err = run_command('bin/kafo-export-params --help', :dir => Dir.pwd)
        code.must_equal 0
        out.must_include 'Usage:'
        out.must_include 'kafo-export-params [OPTIONS]'
      end
    end

    describe 'md format' do
      it 'outputs markdown' do
        generate_installer
        add_manifest

        code, out, err = run_command "kafo-export-params -f md -c #{KAFO_CONFIG}"
        code.must_equal 0
        out.must_match /\| Parameter name\s*\| Description\s*\|/
        out.must_match /\| --testing-db-type\s*\| can be mysql or sqlite\s*\|/
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
          command[1].must_match /\| Parameter name\s*\| Description\s*\|/
          command[1].must_match /\| --testing-db-type\s*\| can be mysql or sqlite\s*\|/
        end
      end

      describe 'html' do
        let(:format) { 'html' }
        it 'must output HTML' do
          command[1].must_include '<th>Option</th>'
          command[1].must_match %r{<td.*>--testing-db-type</td>}
          command[1].must_include '<td>can be mysql or sqlite</td>'
        end
      end

      describe 'asciidoc' do
        let(:format) { 'asciidoc' }
        it 'must output asciidoc' do
          command[1].must_include "Parameters for 'testing':"
          command[1].must_include '--testing-db-type'
          command[1].must_include 'can be mysql or sqlite'
        end
      end

      describe 'parsercache' do
        let(:format) { 'parsercache' }
        it 'must output parser cache JSON' do
          command[1].must_include 'version: 1'
          command[1].must_include 'testing:'
          command[1].must_include 'db_type:'
          command[1].must_include 'can be mysql or sqlite'
        end
      end
    end

    describe 'with parser cache' do
      it 'writes and reads cache' do
        generate_installer
        add_manifest
        File.open(KAFO_CONFIG, 'a') { |f| f.puts ":parser_cache_path: #{INSTALLER_HOME}/parser_cache.json" }

        code, out, err = run_command("kafo-export-params -f parsercache -c #{KAFO_CONFIG} -o #{INSTALLER_HOME}/parser_cache.json")
        code.must_equal 0
        err.must_include 'Using Puppet module parser'
        File.size?("#{INSTALLER_HOME}/parser_cache.json").wont_be_nil

        code, out, err = run_command("kafo-export-params -f asciidoc -c #{KAFO_CONFIG}")
        code.must_equal 0
        err.must_include "Using #{INSTALLER_HOME}/parser_cache.json cache with parsed modules"
        out.must_include "Parameters for 'testing':"
        out.must_include "--testing-db-type"
      end
    end
  end
end
