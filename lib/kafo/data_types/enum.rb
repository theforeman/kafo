module Kafo
  module DataTypes
    class Enum < DataType
      def initialize(*permitted)
        @permitted = permitted
      end

      def to_s
        @permitted.map(&:inspect).join(' or ')
      end

      def valid?(input, errors = [])
        unless input.is_a?(::String)
          errors << "#{input.inspect} is not a valid string"
          return false
        end

        errors << "#{input} must be one of #{@permitted.join(', ')}" unless @permitted.include?(input)
        return errors.empty?
      end
    end

    DataType.register_type('Enum', Enum)
  end
end
