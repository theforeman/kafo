require 'kafo_configure/lib/kafo/puppet/report_wrapper'

module Puppet::Parser::Functions
  newfunction(:add_progress) do |args|
    loaded = false
    begin
      require 'puppet/transaction'
      loaded = true
    rescue LoadError
      ::Puppet.warning 'Unable to load puppet/transaction for progress bar support, this version may not be supported'
    end

    if loaded
      # Monkey patch the transaction to put our wrapper around the report object
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

        def report_with_wrapper
          unless @report_wrapper
            @report_wrapper = Kafo::Puppet::ReportWrapper.new(self, report_without_wrapper)
          end
          @report_wrapper
        end

        if method_defined?(:evaluate) && method_defined?(:report)
          alias_method :evaluate_without_trigger, :evaluate
          alias_method :evaluate, :evaluate_with_trigger
          alias_method :report_without_wrapper, :report
          alias_method :report, :report_with_wrapper
        else
          ::Puppet.warning 'Unable to patch Puppet transactions for progress bar support, this version may not be supported'
        end
      end
    end
  end
end
