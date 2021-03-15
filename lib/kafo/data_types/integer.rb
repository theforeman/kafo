module Kafo
  module DataTypes
    class Integer < DataType
      def initialize(min = :default, max = :default)
        @min = (min.to_s == 'default') ? :infinite : min.to_i
        @max = (max.to_s == 'default') ? :infinite : max.to_i
      end

      def to_s
        if @min != :infinite && @max == :infinite
          "integer (at least #{@min})"
        elsif @min == :infinite && @max != :infinite
          "integer (up to #{@max})"
        elsif @min != :infinite && @max != :infinite
          "integer (between #{@min} and #{@max})"
        else
          "integer"
        end
      end

      def typecast(value)
        Integer(value)
      rescue TypeError, ArgumentError
        value
      end

      def valid?(input, errors = [])
        unless input.is_a?(::Integer)
          errors << "#{input.inspect} is not a valid integer"
          return false
        end

        errors << "#{input} must be at least #{@min}" if @min != :infinite && input < @min
        errors << "#{input} must be up to #{@max}" if @max != :infinite && input > @max

        return errors.empty?
      end
    end

    DataType.register_type('Integer', Integer)
  end
end
