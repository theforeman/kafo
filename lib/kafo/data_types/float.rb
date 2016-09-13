module Kafo
  module DataTypes
    class Float < DataType
      def initialize(min = :default, max = :default)
        @min = (min.to_s == 'default') ? :infinite : min.to_i
        @max = (max.to_s == 'default') ? :infinite : max.to_i
      end

      def to_s
        if @min != :infinite && @max == :infinite
          "float (at least #{@min})"
        elsif @min == :infinite && @max != :infinite
          "float (up to #{@max})"
        elsif @min != :infinite && @max != :infinite
          "float (between #{@min} and #{@max})"
        else
          "float"
        end
      end

      def typecast(value)
        value.to_s =~ /\d+/ ? value.to_f : value
      end

      def valid?(input, errors = [])
        unless input.is_a?(::Float)
          errors << "#{input.inspect} is not a valid float"
          return false
        end

        errors << "#{input} must be at least #{@min}" if @min != :infinite && input < @min
        errors << "#{input} must be up to #{@max}" if @max != :infinite && input > @max

        return errors.empty?
      end
    end

    DataType.register_type('Float', Float)
  end
end
