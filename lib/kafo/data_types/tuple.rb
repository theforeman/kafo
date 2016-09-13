module Kafo
  module DataTypes
    class Tuple < DataType
      def initialize(*args)
        if args.last.to_s =~ /\d+/ || args.last.to_s == 'default'
          max = args.pop
          min = args.pop
        else
          max = :default
          min = :default
        end
        @max = (max.to_s == 'default') ? :infinite : max.to_i
        @min = (min.to_s == 'default') ? 0 : min.to_i
        @inner_types = args.map { |type| DataType.new_from_string(type) }
      end

      def condition_value(value)
        "[ #{value.each_with_index.map { |v,i| inner_types(value)[i].condition_value(v) }.join(', ')} ]"
      end

      def multivalued?
        true
      end

      def to_s
        type = "tuple of #{@inner_types.join(', ')}"
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
          values = [value].flatten
          values.each_with_index.map { |v,i| inner_types(values)[i].typecast(v) }
        end
      end

      def valid?(input, errors = [])
        unless input.is_a?(::Array)
          errors << "#{input.inspect} is not a valid tuple"
          return false
        end

        inner_errors = []
        input.each_with_index { |v,i| inner_types(input)[i].valid?(v, inner_errors) }
        unless inner_errors.empty?
          errors << "Elements of the tuple are invalid: #{inner_errors.join(', ')}"
        end

        errors << "The tuple must have at least #{@min} items" if input.size < @min
        errors << "The tuple must have at maximum #{@max} items" if @max != :infinite && input.size > @max

        return errors.empty?
      end

      private

      def inner_types(value)
        @inner_types + ([@inner_types.last] * (value.size - @inner_types.size))
      end
    end

    DataType.register_type('Tuple', Tuple)
  end
end
