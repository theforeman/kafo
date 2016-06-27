module Kafo
  module DataTypes
    class Undef < DataType
      def valid?(input, errors = [])
        errors << "#{input} must be undef" unless input.nil?
        return errors.empty?
      end
    end

    DataType.register_type('Undef', Undef)
  end
end
