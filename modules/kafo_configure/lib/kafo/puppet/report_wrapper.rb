require 'set'

module Kafo
  module Puppet
    class ReportWrapper
      attr_reader :transaction, :report

      def initialize(transaction, report)
        @transaction     = transaction
        @report          = report
        @supported       = true
        @resources_seen  = Set.new
      end

      # Needed to fool Puppet's logging framework
      def self.to_s
        "Puppet::Transaction::Report"
      end

      def add_resource_status(status, *args, &block)
        if @supported && report.respond_to?(:resource_statuses) && report.resource_statuses.is_a?(Hash)
          if transaction.in_main_catalog && report.resource_statuses[status.resource.to_s] && transaction.tracked_resources.include?(status.resource) && !@resources_seen.include?(status.resource)
            ::Puppet.info "RESOURCE #{status.resource}"
            @resources_seen << status.resource
          end
          report.add_resource_status(status, *args, &block)
        else
          ::Puppet.err "Your puppet env is not supported, report does not define resource_statuses"
          @supported = false
        end
      end

      def method_missing(method, *args, &block)
        report.send(method, *args, &block)
      end
    end

  end
end
