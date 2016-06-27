module Kafo
  module DataTypes
    class Hash < DataType
      def initialize(inner_key_type = 'Scalar', inner_value_type = 'Data', min = :default, max = :default)
        @inner_key_type = DataType.new_from_string(inner_key_type)
        @inner_value_type = DataType.new_from_string(inner_value_type)
        @min = (min.to_s == 'default') ? 0 : min.to_i
        @max = (max.to_s == 'default') ? :infinite : max.to_i
      end

      def multivalued?
        true
      end

      def to_s
        type = "hash of #{@inner_key_type}/#{@inner_value_type}"
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
        elsif value.is_a?(::Hash)
          value
        elsif value == ['EMPTY_HASH']
          {}
        else
          ::Hash[[value].flatten.map do |kv|
            k, v = kv.split(':', 2)
            [@inner_key_type.typecast(k), @inner_value_type.typecast(v)]
          end]
        end
      end

      def valid?(input, errors = [])
        unless input.is_a?(::Hash)
          errors << "#{input.inspect} is not a valid hash"
          return false
        end

        inner_key_errors = []
        input.keys.each { |v| @inner_key_type.valid?(v, inner_key_errors) }
        unless inner_key_errors.empty?
          errors << "Hash key elements are invalid: #{inner_key_errors.join(', ')}"
        end

        inner_value_errors = []
        input.values.each { |v| @inner_value_type.valid?(v, inner_value_errors) }
        unless inner_value_errors.empty?
          errors << "Hash value elements are invalid: #{inner_value_errors.join(', ')}"
        end

        errors << "The hash must have at least #{@min} items" if input.size < @min
        errors << "The hash must have at maximum #{@max} items" if @max != :infinite && input.size > @max

        return errors.empty?
      end
    end

    DataType.register_type('Hash', Hash)
  end
end
