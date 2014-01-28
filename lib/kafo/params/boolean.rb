module Kafo
  module Params
    class Boolean < Param
      def value=(value)
        super
        @value = typecast(@value)
      end

      def dump_default
        %{"#{super}"}
      end

      private

      def typecast(value)
        case value
          when '0', 'false', 'f', 'n', false
            false
          when '1', 'true', 't', 'y', true
            true
          else
            value
        end
      end
    end
  end
end
