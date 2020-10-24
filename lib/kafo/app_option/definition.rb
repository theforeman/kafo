module Kafo
  module AppOption
    class Definition < Clamp::Option::Definition

      def initialize(switches, type, description, options = {})
        super(switches, type, description, options)
      end

    end
  end
end
