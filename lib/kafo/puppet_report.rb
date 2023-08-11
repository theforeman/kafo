module Kafo
  # An abstraction over the Puppet report format
  #
  # @see https://puppet.com/docs/puppet/8/format_report.html
  class PuppetReport
    # Load a Puppet report from a path
    #
    # Both YAML and JSON are supported.
    #
    # @param [String] path
    #   The path to Puppet report
    #
    # @return [PuppetReport] The report from the path
    def self.load_report_file(path)
      raise ArgumentError, 'No path given' unless path || path.empty?
      raise ArgumentError, "#{path} is not a readable file" unless File.file?(path) && File.readable?(path)

      data = case File.extname(path)
             when '.yaml'
               require 'yaml'
               content = File.read(path).gsub(%r{\!ruby/object.*$}, '')
               YAML.safe_load(content, permitted_classes: [Time, Symbol])
             when '.json'
               require 'json'
               JSON.parse(File.read(path))
             else
               raise ArgumentError, "Unsupported file extension for #{path}"
             end

      PuppetReport.new(data)
    end

    # @param [Hash] report
    #   The Puppet report
    def initialize(report)
      @report = report
    end

    # @return [Integer] The report format
    def report_format
      @report['report_format']
    end

    # @return [Array[Hash]] The Puppet logs
    def logs
      @report['logs']
    end

    # @return [Array[PuppetFailedResource]] The failed resources and their status
    def failed_resources
      statuses = @report['resource_statuses']

      raise PuppetReportError, "No resource statuses found in report" unless statuses

      statuses.select { |_title, status| status['failed'] }.map do |title, status|
        # TODO: There's also a message with source Puppet
        # Executing with uid=USER: '/tmp/failing-command'
        # This shows up after Executing '/tmp/failing-command'
        related_logs = logs.select { |log| log['source'].include?(title) }
        PuppetFailedResource.new(status, related_logs)
      end
    end
  end
end
