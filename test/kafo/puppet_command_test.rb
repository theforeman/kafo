require 'test_helper'

module Kafo
  describe PuppetModule do
    before do
      KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path, logger: Kafo::KafoConfigure.logger)
    end

    let(:pc) { PuppetCommand.new '' }

    describe "#command" do
      describe "with defaults" do
        specify { _(pc.command).must_be_kind_of String }
        specify { _(pc.command).must_include 'puppet apply --modulepath /' }
        specify { _(pc.command).must_include 'kafo_configure::puppet_version_semver { "theforeman-kafo_configure":' }

        specify { PuppetCommand.stub(:search_puppet_path, '/opt/puppetlabs/bin/puppet') { _(pc.command).must_include '/opt/puppetlabs/bin/puppet apply' } }
      end

      describe "with PuppetConfigurer" do
        let(:puppetconf) { Minitest::Mock.new }
        let(:pc) { PuppetCommand.new '', [], puppetconf }

        specify do
          puppetconf.expect(:config_path, '/tmp/puppet.conf') do
            puppetconf.expect(:write_config, nil) do
              _(pc.command).must_include ' --config=/tmp/puppet.conf '
            end
          end
        end
      end

      describe "with version checks" do
        specify do
          pc.stub(:modules_path, ['/modules']) do
            Dir.stub(:[], ['./test/fixtures/metadata/basic.json']) do
              _(pc.command).must_include 'kafo_configure::puppet_version_semver { "theforeman-testing":'
              _(pc.command).must_include 'requirement => ">= 3.0.0 < 999.0.0"'
            end
          end
        end

        specify do
          KafoConfigure.config.app[:skip_puppet_version_check] = true
          pc.stub(:modules_path, ['/modules']) do
            Dir.stub(:[], ['./test/fixtures/metadata/basic.json']) do
              _(pc.command).wont_include 'kafo_configure::puppet_version'
            end
          end
        end
      end
    end

    describe '.search_puppet_path' do
      let(:pc) { PuppetCommand.search_puppet_path('puppet') }

      describe "with 'puppet' in PATH" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, proc { |path| path == '/usr/local/bin/puppet' }) do
              _(pc).must_equal '/usr/local/bin/puppet'
            end
          end
        end
      end

      describe "with AIO 'puppet' only" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, proc { |path| path == '/opt/puppetlabs/bin/puppet' }) do
              _(pc).must_equal '/opt/puppetlabs/bin/puppet'
            end
          end
        end
      end

      describe "with no 'puppet' found in PATH" do
        specify { File.stub(:executable?, false) { _(pc).must_equal 'puppet' } }
      end
    end

    describe '.aio_puppet?' do
      subject do
        PuppetCommand.stub(:format_command, puppet_command) do
          PuppetCommand.aio_puppet?
        end
      end

      describe 'with an absolute path' do
        let(:puppet_command) { '/usr/bin/puppet' }

        specify 'as a real file' do
          File.stub(:realpath, proc { |path| path }) do
            refute subject
          end
        end

        specify 'as a symlink to AIO' do
          File.stub(:realpath, '/opt/puppetlabs/puppet/bin/wrapper.sh') do
            assert subject
          end
        end

        specify 'as a broken symlink' do
          File.stub(:realpath, proc { |_path| raise Errno::ENOENT, 'No such file or directory' }) do
            refute subject
          end
        end
      end

      describe 'with a relative path' do
        let(:puppet_command) { 'puppet' }

        specify 'non-existant' do
          File.stub(:realpath, proc { |_path| raise Errno::ENOENT, 'No such file or directory' }) do
            refute subject
          end
        end
      end
    end

    describe '.format_command' do
      describe 'with Puppet AIO' do
        specify 'with a string' do
          PuppetCommand.stub(:aio_puppet?, true) do
            PuppetCommand.stub(:clean_env_vars, {'FOO' => 'bar'}) do
              expected = [{'FOO' => 'bar'}, 'echo hello world', { :unsetenv_others => true }]
              assert_equal(expected, PuppetCommand.format_command('echo hello world'))
            end
          end
        end

        specify 'with an array' do
          PuppetCommand.stub(:aio_puppet?, true) do
            PuppetCommand.stub(:clean_env_vars, {'FOO' => 'bar'}) do
              expected = [{'FOO' => 'bar'}, 'echo', 'hello', 'world', { :unsetenv_others => true }]
              assert_equal(expected, PuppetCommand.format_command(['echo', 'hello', 'world']))
            end
          end
        end

        specify 'with extra env' do
          PuppetCommand.stub(:aio_puppet?, true) do
            PuppetCommand.stub(:clean_env_vars, {'FOO' => 'bar'}) do
              expected = [{'FOO' => 'bar', 'EXTRA' => 'cool'}, 'echo hello world', { :unsetenv_others => true }]
              assert_equal(expected, PuppetCommand.format_command(['echo hello world'], { 'EXTRA' => 'cool' }))
            end
          end
        end
      end

      describe 'with regular Puppet' do
        specify 'with a string' do
          PuppetCommand.stub(:aio_puppet?, false) do
            expected = [::ENV.to_h, 'echo hello world', { :unsetenv_others => false }]
            assert_equal(expected, PuppetCommand.format_command('echo hello world'))
          end
        end

        specify 'with an array' do
          PuppetCommand.stub(:aio_puppet?, false) do
            expected = [::ENV.to_h, 'echo', 'hello', 'world', { :unsetenv_others => false }]
            assert_equal(expected, PuppetCommand.format_command(['echo', 'hello', 'world']))
          end
        end

        specify 'with extra env' do
          PuppetCommand.stub(:aio_puppet?, false) do
            expected_env = ::ENV.to_h.merge({ 'EXTRA' => 'cool' })
            expected = [expected_env, 'echo hello world', { :unsetenv_others => false }]
            assert_equal(expected, PuppetCommand.format_command('echo hello world', { 'EXTRA' => 'cool' }))
          end
        end
      end
    end
  end
end
