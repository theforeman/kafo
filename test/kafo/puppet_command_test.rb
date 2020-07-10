require 'test_helper'

module Kafo
  describe PuppetModule do
    before do
      KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
    end

    let(:pc) { PuppetCommand.new '' }

    describe "#command" do
      describe "with defaults" do
        specify { _(pc.command).must_be_kind_of String }
        specify { _(pc.command).must_include 'puppet apply --modulepath /' }
        specify { _(pc.command).must_include 'kafo_configure::puppet_version_semver { "theforeman-kafo_configure":' }

        specify { KafoConfigure.stub(:verbose, false) { _(pc.command).must_include '$kafo_add_progress=true' } }
        specify { KafoConfigure.stub(:verbose, true) { _(pc.command).must_include '$kafo_add_progress=false' } }

        specify { PuppetCommand.stub(:search_puppet_path, '/opt/puppetlabs/bin/puppet') { _(pc.command).must_include '/opt/puppetlabs/bin/puppet apply' } }
      end

      describe "with PuppetConfigurer" do
        let(:puppetconf) { MiniTest::Mock.new }
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
            File.stub(:executable?, Proc.new { |path| path == '/usr/local/bin/puppet' }) do
              _(pc).must_equal '/usr/local/bin/puppet'
            end
          end
        end
      end

      describe "with 'puppet' in PATH as symlink" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, Proc.new { |path| path == '/opt/puppetlabs/bin/puppet' }) do
              File.stub(:symlink?, Proc.new { |path| ['/usr/bin/puppet', '/usr/local/bin/puppet'].include?(path) }) do
                _(pc).must_equal '/opt/puppetlabs/bin/puppet'
              end
            end
          end
        end
      end

      describe "with AIO 'puppet' only" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, Proc.new { |path| path == '/opt/puppetlabs/bin/puppet' }) do
              File.stub(:symlink?, false) do
                _(pc).must_equal '/opt/puppetlabs/bin/puppet'
              end
            end
          end
        end
      end

      describe "with no 'puppet' found in PATH" do
        specify { File.stub(:executable?, false) { _(pc).must_equal 'puppet' } }
      end
    end
  end
end
