module Kafo
  module DataTypes
    class Numeric < DataType
      def typecast(value)
        value =~ /\d+/ ? value.to_f : value
      end

      def valid?(input, errors = [])
        errors << "#{input.inspect} is not a valid number" unless input.is_a?(::Integer) || input.is_a?(::Float)
        return errors.empty?
      end
    end

    DataType.register_type('Numeric', Numeric)
  end
end
