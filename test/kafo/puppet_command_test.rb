require 'test_helper'

module Kafo
  describe PuppetModule do
    before do
      KafoConfigure.config = Configuration.new(ConfigFileFactory.build('basic', BASIC_CONFIGURATION).path)
    end

    let(:pc) { PuppetCommand.new '' }

    describe "#command" do
      describe "with defaults" do
        specify { pc.command.must_be_kind_of String }
        specify { pc.command.must_include 'puppet apply --modulepath /' }
        specify { pc.command.wont_include 'kafo_configure::puppet_version' }

        specify { KafoConfigure.stub(:verbose, false) { pc.command.must_include '$kafo_add_progress="true"' } }
        specify { KafoConfigure.stub(:verbose, true) { pc.command.must_include '$kafo_add_progress="false"' } }

        specify { PuppetCommand.stub(:search_puppet_path, '/opt/puppetlabs/bin/puppet') { pc.command.must_include '/opt/puppetlabs/bin/puppet apply' } }
      end

      describe "with PuppetConfigurer" do
        let(:puppetconf) { MiniTest::Mock.new }
        let(:pc) { PuppetCommand.new '', [], puppetconf }

        specify do
          puppetconf.expect(:config_path, '/tmp/puppet.conf') do
            puppetconf.expect(:write_config, nil) do
              pc.command.must_include ' --config=/tmp/puppet.conf '
            end
          end
        end
      end

      describe "with version checks" do
        specify do
          pc.stub(:modules_path, ['/modules']) do
            Dir.stub(:[], ['./test/fixtures/metadata/basic.json']) do
              pc.command.must_include 'kafo_configure::puppet_version_semver { "theforeman-testing":'
              pc.command.must_include 'requirement => ">= 3.0.0 < 999.0.0"'
              pc.command.must_include 'kafo_configure::puppet_version_versioncmp { "theforeman-testing":'
              pc.command.must_include 'minimum => "3.0.0",'
              pc.command.must_include 'maximum => "999.0.0",'
            end
          end
        end

        specify do
          KafoConfigure.config.app[:skip_puppet_version_check] = true
          pc.stub(:modules_path, ['/modules']) do
            Dir.stub(:[], ['./test/fixtures/metadata/basic.json']) do
              pc.command.wont_include 'kafo_configure::puppet_version'
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
              pc.must_equal '/usr/local/bin/puppet'
            end
          end
        end
      end

      describe "with AIO 'puppet' only" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, Proc.new { |path| path == '/opt/puppetlabs/bin/puppet' }) do
              pc.must_equal '/opt/puppetlabs/bin/puppet'
            end
          end
        end
      end

      describe "with no 'puppet' found in PATH" do
        specify { File.stub(:executable?, false) { pc.must_equal 'puppet' } }
      end
    end
  end
end
