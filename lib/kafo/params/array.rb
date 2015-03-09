module Kafo
  module Params
    class Array < Param
      def value=(value)
        super
        if @value == ['EMPTY_ARRAY']
          @value = []
        else
          @value = typecast(@value)
        end
      end

      def multivalued?
        true
      end

      def condition_value
        "[ #{value.map(&:inspect).join(', ')} ]"
      end

      private

      def typecast(value)
        value.nil? ? nil : [value].flatten
      end
    end
  end
end
