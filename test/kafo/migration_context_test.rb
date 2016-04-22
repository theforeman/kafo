require 'test_helper'

module Kafo
  describe MigrationContext do
    let(:context) { MigrationContext.new({}, {}) }

    describe "api" do
      specify { context.respond_to?(:logger) }
      specify { context.respond_to?(:scenario) }
      specify { context.respond_to?(:answers) }
      specify { context.respond_to?(:facts) }
    end

    describe '#facts' do
      specify { MigrationContext.stub(:facts, {:foo => 'bar'}) { context.facts.must_equal(:foo => 'bar') } }
    end

    describe '.facts' do
      specify { MigrationContext.stub(:`, {'foo' => 'bar'}.to_yaml) { MigrationContext.facts.must_equal(:foo => 'bar') } }
      specify do
        PuppetCommand.stub(:search_puppet_path, Proc.new { |bin| '/opt/puppetlabs/bin/facter' if bin == 'facter' }) do
          MigrationContext.stub(:`, Proc.new { |cmd| {'foo' => 'bar'}.to_yaml if cmd == '/opt/puppetlabs/bin/facter --yaml' }) do
            MigrationContext.facts.must_equal(:foo => 'bar')
          end
        end
      end
    end
  end
end
