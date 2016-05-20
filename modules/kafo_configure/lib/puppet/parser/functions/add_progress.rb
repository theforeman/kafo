require 'kafo_configure/lib/kafo/puppet/report_wrapper'

module Puppet::Parser::Functions
  newfunction(:add_progress) do |args|
    supported = %w(2.6. 2.7. 3.0. 3.1. 3.2. 3.3. 3.4. 3.5. 3.6. 3.7. 3.8.)
    if supported.any? { |version| Puppet::PUPPETVERSION.start_with?(version) }
      # Monkey patch the transaction to put our wrapper around the report object
      require 'puppet/transaction'
      class Puppet::Transaction
        attr_accessor :in_main_catalog

        def is_interesting?(resource)
          ![:schedule, :class, :stage, :filebucket, :anchor, :'kafo_configure::yaml_to_class'].include?(resource.to_s.split('[')[0].downcase.to_sym)
        end

        def tracked_resources
          @tracked_resources ||= catalog.vertices.select { |resource| is_interesting?(resource) }.map(&:to_s)
        end

        def evaluate_with_trigger(*args, &block)
          if catalog.version
            self.in_main_catalog = true
            ::Puppet.info "START #{tracked_resources.size}"
          end
          evaluate_without_trigger(*args, &block)
          self.in_main_catalog = false if catalog.version
        end

        alias_method :evaluate_without_trigger, :evaluate
        alias_method :evaluate, :evaluate_with_trigger

        def report_with_wrapper
          unless @report_wrapper
            @report_wrapper = Kafo::Puppet::ReportWrapper.new(self, report_without_wrapper)
          end
          @report_wrapper
        end

        alias_method :report_without_wrapper, :report
        alias_method :report, :report_with_wrapper
      end
    else
      ::Puppet.warning 'Your puppet version does not support progress bar'
    end
  end
end
