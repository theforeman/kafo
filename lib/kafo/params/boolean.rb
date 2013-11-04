module Kafo
  module Params
    class Boolean < Param
      def value=(value)
        super
        @value = typecast(@value)
      end

      private

      def typecast(value)
        case value
          when '0', 'false', 'f', false
            false
          when '1', 'true', 't', true
            true
          else
            value
        end
      end
    end
  end
end
