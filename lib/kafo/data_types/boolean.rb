module Kafo
  module DataTypes
    class Boolean < DataType
      def initialize(*permitted)
        @permitted = permitted
      end

      def typecast(value)
        case value
          when '0', 'false', 'f', 'n', false
            false
          when '1', 'true', 't', 'y', true
            true
          else
            value
        end
      end

      def valid?(input, errors = [])
        (input.is_a?(::TrueClass) || input.is_a?(::FalseClass)).tap do |valid|
          errors << "#{input.inspect} is not a valid boolean" unless valid
        end

        unless @permitted.empty? || @permitted.include?(input)
          errors << "#{input} must be one of #{@permitted.join(', ')}"
        end

        return errors.empty?
      end
    end

    DataType.register_type('Boolean', Boolean)
  end
end
