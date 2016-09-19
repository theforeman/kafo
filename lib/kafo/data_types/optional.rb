require 'forwardable'

module Kafo
  module DataTypes
    class Optional < DataType
      extend Forwardable
      def_delegators :@inner_type, :condition_value, :dump_default, :multivalued?, :typecast
      attr_reader :inner_type, :inner_value

      def initialize(inner_type_or_value)
        begin
          @inner_type = DataType.new_from_string(inner_type_or_value)
        rescue ConfigurationException
          @inner_value = inner_type_or_value
        end
      end

      def to_s
        if @inner_type
          "#{@inner_type} or undef"
        else
          "#{@inner_value.inspect} or undef"
        end
      end

      def valid?(input, errors = [])
        return true if input.nil?
        return true if @inner_type && @inner_type.valid?(input, errors)
        return true if @inner_value && @inner_value == input
        return false
      end
    end

    DataType.register_type('Optional', Optional)
  end
end
