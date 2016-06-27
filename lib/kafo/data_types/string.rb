module Kafo
  module DataTypes
    class String < DataType
      def initialize(min = :default, max = :default)
        @min = (min.to_s == 'default') ? 0 : min.to_i
        @max = (max.to_s == 'default') ? :infinite : max.to_i
      end

      def to_s
        if @min > 0 && @max == :infinite
          "string (at least #{@min} characters)"
        elsif @min == 0 && @max != :infinite
          "string (up to #{@max} characters)"
        elsif @min > 0 && @max != :infinite
          "string (between #{@min} and #{@max} characters)"
        else
          "string"
        end
      end

      def valid?(input, errors = [])
        unless input.is_a?(::String)
          errors << "#{input.inspect} is not a valid string"
          return false
        end

        errors << "#{input} must be at least #{@min}" if input.size < @min
        errors << "#{input} must be up to #{@max}" if @max != :infinite && input.size > @max

        return errors.empty?
      end
    end

    DataType.register_type('String', String)
  end
end
