module Kafo
  module DataTypes
    class WrappedDataType < DataType
      def initialize(*inner_types)
        @inner_types = inner_types.map { |t| DataType.new_from_string(t) }
      end

      def condition_value(value)
        type = find_type(value)
        type ? type.condition_value(value) : super(value)
      end

      def dump_default(value)
        type = find_type(value)
        type ? type.dump_default(value) : super(value)
      end

      def multivalued?
        @inner_types.any?(&:multivalued?)
      end

      def to_s
        @inner_types.join(' or ')
      end

      def typecast(value)
        type = find_type(value)
        type ? type.typecast(value) : value
      end

      def valid?(value, errors = [])
        type = find_type(value)
        if type
          type.valid?(value, errors)
        else
          errors << "#{value} is not one of #{self}"
          false
        end
      end

      private

      def find_type(value)
        @inner_types.find { |t| t.valid?(t.typecast(value)) }
      end
    end

    DataType.register_type('Sensitive', WrappedDataType)
    DataType.register_type('Variant', WrappedDataType)
  end
end
