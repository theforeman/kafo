require_relative 'definition'

module Kafo
  module AppOption
    module Declaration
      include Clamp::Option::Declaration

      def app_option(switches, type, description, opts = {}, &block)
        AppOption::Definition.new(switches, type, description, opts).tap do |option|
          block ||= option.default_conversion_block
          define_accessors_for(option, &block)
          declared_options << option
        end
      end
    end
  end
end
