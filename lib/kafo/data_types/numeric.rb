module Kafo
  module DataTypes
    class Numeric < DataType
      def typecast(value)
        Float(value)
      rescue TypeError, ArgumentError
        value
      end

      def valid?(input, errors = [])
        errors << "#{input.inspect} is not a valid number" unless input.is_a?(::Integer) || input.is_a?(::Float)
        return errors.empty?
      end
    end

    DataType.register_type('Numeric', Numeric)
  end
end
