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

        specify { KafoConfigure.stub(:verbose, false) { pc.command.must_include '$kafo_add_progress=true' } }
        specify { KafoConfigure.stub(:verbose, true) { pc.command.wont_include '$kafo_add_progress' } }

        specify { KafoConfigure.stub(:temp_config_file, '/tmp/answer') { pc.command.must_include '$kafo_answer_file="/tmp/answer"' } }
        specify { KafoConfigure.stub(:temp_config_file, nil) { pc.command.wont_include '$kafo_answer_file' } }
      end

      describe "with 'puppet' in PATH" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, Proc.new { |path| path == '/usr/local/bin/puppet' }) do
              pc.command.must_include '/usr/local/bin/puppet apply'
            end
          end
        end
      end

      describe "with AIO 'puppet' only" do
        specify do
          ::ENV.stub(:[], '/usr/bin:/usr/local/bin') do
            File.stub(:executable?, Proc.new { |path| path == '/opt/puppetlabs/bin/puppet' }) do
              pc.command.must_include '/opt/puppetlabs/bin/puppet apply'
            end
          end
        end
      end

      describe "with no 'puppet' found in PATH" do
        specify { File.stub(:executable?, false) { pc.command.must_include ' puppet apply' } }
      end
    end
  end
end
