require 'test_helper'

module Kafo
  describe MigrationContext do
    let(:context) { MigrationContext.new({}, {}) }

    before(:each) { MigrationContext.clear_caches }

    describe "api" do
      specify { context.respond_to?(:logger) }
      specify { context.respond_to?(:scenario) }
      specify { context.respond_to?(:answers) }
      specify { context.respond_to?(:facts) }
    end

    describe '#facts' do
      specify { MigrationContext.stub(:facts, {:foo => 'bar'}) { _(context.facts).must_equal(:foo => 'bar') } }
    end

    describe '.facts' do
      specify { MigrationContext.stub(:run_command, {'foo' => 'bar'}.to_json) { _(MigrationContext.facts).must_equal(:foo => 'bar') } }

      specify do
        PuppetCommand.stub(:search_puppet_path, Proc.new { |bin| '/opt/puppetlabs/bin/facter' if bin == 'facter' }) do
          MigrationContext.stub(:run_command, Proc.new { |cmd| {'puppet' => 'labs'}.to_json if cmd == '/opt/puppetlabs/bin/facter --json' }) do
            _(MigrationContext.facts).must_equal(:puppet => 'labs')
          end
        end
      end

      specify do
        MigrationContext.stub(:run_command, {'foo' => 'bar', 'first' => {'second' => ['value']}}.to_json) do
          _(MigrationContext.facts).must_equal(:foo => 'bar', :first => {:second => ['value']})
        end
      end
    end
  end
end
