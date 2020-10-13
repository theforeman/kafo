require 'test_helper'

describe Kafo::PuppetReport do
  describe '.report_format' do
    let(:report) { { 'report_format' => 11 } }
    let(:puppet_report) { Kafo::PuppetReport.new(report) }

    specify { assert_equal(11, puppet_report.report_format) }
  end

  describe '#load_report_file' do
    let(:puppet_report) { Kafo::PuppetReport.load_report_file(path) }

    describe 'with format-12.yaml fixture' do
      let(:path) { File.join(__dir__, '..', 'fixtures', 'reports', 'format-12.yaml') }

      describe '.failed_resources' do
        let(:failed_resource) { puppet_report.failed_resources.first }

        specify { assert_equal(1, puppet_report.failed_resources.length) }
        specify { assert_equal('Exec[failing-command]', failed_resource.resource) }
        specify { assert_equal('Exec', failed_resource.type) }
        specify { assert_equal('failing-command', failed_resource.title) }
        specify { assert_equal("Puppet Exec resource 'failing-command'", failed_resource.to_s) }

        specify do
          expected_event_messsages = [
            "change from 'notrun' to ['0'] failed: '/tmp/failing-command' returned 100 instead of one of [0]"
          ]
          assert_equal(expected_event_messsages, failed_resource.event_messages)
        end

        specify do
          expected_log_messages = [
            "require to File[/tmp/failing-command]",
            "Starting to evaluate the resource (12 of 21)",
            "Executing '/tmp/failing-command'",
            "This is stdout",
            "This is stderr",
            "change from 'notrun' to ['0'] failed: '/tmp/failing-command' returned 100 instead of one of [0]",
            "Evaluated in 0.01 seconds"
          ]
          assert_equal(expected_log_messages, failed_resource.log_messages)
        end
      end

      describe '.report_format' do
        specify { assert_equal(12, puppet_report.report_format) }
      end
    end
  end
end
