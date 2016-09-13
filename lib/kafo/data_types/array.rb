module Kafo
  module DataTypes
    class Array < DataType
      def initialize(inner_type = 'Data', min = :default, max = :default)
        @inner_type = DataType.new_from_string(inner_type)
        @min = (min.to_s == 'default') ? 0 : min.to_i
        @max = (max.to_s == 'default') ? :infinite : max.to_i
      end

      def condition_value(value)
        "[ #{value.map { |v| @inner_type.condition_value(v) }.join(', ')} ]"
      end

      def multivalued?
        true
      end

      def to_s
        type = "array of #{@inner_type}"
        if @min > 0 && @max == :infinite
          "#{type} (at least #{@min} items)"
        elsif @min == 0 && @max != :infinite
          "#{type} (up to #{@max} items)"
        elsif @min > 0 && @max != :infinite
          "#{type} (between #{@min} and #{@max} items)"
        else
          type
        end
      end

      def typecast(value)
        if value.nil?
          nil
        elsif value == ['EMPTY_ARRAY']
          []
        else
          [value].flatten.map { |v| @inner_type.typecast(v) }
        end
      end

      def valid?(input, errors = [])
        unless input.is_a?(::Array)
          errors << "#{input.inspect} is not a valid array"
          return false
        end

        inner_errors = []
        input.each { |v| @inner_type.valid?(v, inner_errors) }
        unless inner_errors.empty?
          errors << "Elements of the array are invalid: #{inner_errors.join(', ')}"
        end

        errors << "The array must have at least #{@min} items" if input.size < @min
        errors << "The array must have at maximum #{@max} items" if @max != :infinite && input.size > @max

        return errors.empty?
      end
    end

    DataType.register_type('Array', Array)
  end
end
