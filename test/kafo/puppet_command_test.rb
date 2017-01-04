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
