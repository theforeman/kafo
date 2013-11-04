module Kafo
  module Params
    class Array < Param
      def value=(value)
        super
        @value = typecast(@value)
      end

      def multivalued?
        true
      end

      private

      def typecast(value)
        value.nil? ? nil : [value].flatten
      end
    end
  end
end
