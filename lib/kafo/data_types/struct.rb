module Kafo
  module DataTypes
    class Struct < DataType
      def initialize(spec)
        @spec = ::Hash[spec.map do |k,v|
          begin
            k = DataType.new_from_string(k)
          rescue ConfigurationException; end
          begin
            v = DataType.new_from_string(v)
          rescue ConfigurationException; end
          [k, v]
        end]
      end

      def multivalued?
        true
      end

      def to_s
        "struct containing " + @spec.keys.map do |k|
          if k.is_a?(Optional)
            [k.inner_value, %{"#{k.inner_value}" (optional #{@spec[k]})}]
          elsif k.is_a?(NotUndef)
            [k.inner_value, %{"#{k.inner_value}" (required #{@spec[k]})}]
          else
            [k, %{"#{k}" (#{@spec[k]})}]
          end
        end.sort_by(&:first).map(&:last).join(', ')
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
            if (value_type = spec_value(k))
              [k, value_type.typecast(v)]
            else
              [k, v]
            end
          end]
        end
      end

      def valid?(input, errors = [])
        unless input.is_a?(::Hash)
          errors << "#{input.inspect} is not a valid struct"
          return false
        end

        required_keys = @spec.keys.select { |k| k.is_a?(NotUndef) }.map { |k| k.inner_value }
        missing_keys = required_keys - input.keys
        errors << "Struct elements are missing: #{missing_keys.join(', ')}" unless missing_keys.empty?

        known_keys = @spec.keys.map { |k| spec_key_name(k) }
        extra_keys = input.keys - known_keys
        errors << "Struct elements are not permitted: #{extra_keys.join(', ')}" unless extra_keys.empty?

        value_errors = []

        # Only check values for optional keys if present
        optional_keys = @spec.keys.select { |k| k.is_a?(Optional) }.map { |k| k.inner_value }
        (optional_keys & input.keys).each { |k| spec_value(k).valid?(input[k], value_errors) }

        # For non-optional and non-required keys, assume nil/undef values if absent
        regular_keys = @spec.keys.select { |k| !k.is_a?(Optional) }.map { |k| spec_key_name(k) }
        regular_keys.each { |k| spec_value(k).valid?(input[k], value_errors) }

        errors << "Struct values are invalid: #{value_errors.join(', ')}" unless value_errors.empty?

        return errors.empty?
      end

      private

      def spec_value(key)
        spec_entry = @spec.find do |k,v|
          spec_key_name(k) == key
        end
        spec_entry ? spec_entry.last : nil
      end

      def spec_key_name(key)
        if key.is_a?(Optional) || key.is_a?(NotUndef)
          key.inner_value
        else
          key
        end
      end
    end

    DataType.register_type('Struct', Struct)
  end
end
