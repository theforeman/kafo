module Kafo
  # An abstraction over the Puppet report format
  #
  # @see https://puppet.com/docs/puppet/6.18/format_report.html
  class PuppetReport
    attr_reader :report

    def self.load_report_file(path)
      raise ArgumentError, 'No path given' unless path || path.empty?
      raise ArgumentError, "#{path} is not a readable file" unless File.file?(path) && File.readable?(path)

      data = case File.extname(path)
             when '.yaml'
               require 'yaml'
               YAML.load_file(path)
             when '.json'
               require 'json'
               JSON.parse(File.read(path))
             else
               raise ArgumentError, "Unsupported file extension for #{path}"
             end

      PuppetReport.new(data)
    end

    def initialize(report)
      @report = report
    end

    def report_format
      report['report_format']
    end
  end
end
