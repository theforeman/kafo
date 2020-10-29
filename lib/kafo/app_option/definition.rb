module Kafo
  module AppOption
    class Definition < Clamp::Option::Definition
      def initialize(switches, type, description, options = {})
        @advanced = options.fetch(:advanced, false)
        super(switches, type, description, options)
      end

      def advanced?
        @advanced
      end
    end
  end
end
