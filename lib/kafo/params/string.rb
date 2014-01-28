module Kafo
  module Params
    class String < Param
      def condition_value
        %{"#{value}"}
      end

      def dump_default
        %{"#{super}"}
      end
    end
  end
end
