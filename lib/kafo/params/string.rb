module Kafo
  module Params
    class String < Param
      def condition_value
        %{"#{value}"}
      end
    end
  end
end
