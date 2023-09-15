module Kafo
  class PuppetFailedResource
    # @param [Hash] status
    #   The status hash from the report
    # @param [Array[Hash]] logs
    #   Relevant log lines for this resoure
    def initialize(status, logs)
      @status = status
      @logs = logs
    end

    # @example
    #   puppet_failed_resource.resource == 'Exec[/bin/true]'
    # @return [String] A resource
    def resource
      @status['resource']
    end

    # @example
    #   puppet_failed_resource.type == 'Exec'
    # @return [String] A resource type
    def type
      @status['resource_type']
    end

    # @example
    #   puppet_failed_resource.title == '/bin/true'
    # @return [String] A resource title
    def title
      @status['title']
    end

    def to_s
      "Puppet #{type} resource '#{title}'"
    end

    # @return [Array[String]] The event messages
    def event_messages
      @status['events'].map { |event| event['message'] }
    end

    # A collection of Puppet log messages
    #
    # The log messages include detailed information of what failed. Some debug
    # information, such as timing but crucially the command output, both stdout
    # and stderr.
    #
    # @return [Array[String]] The Puppet log messages for this resource
    def log_messages
      @logs.map { |log| log['message'] }
    end
  end
end
