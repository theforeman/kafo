require 'forwardable'

module Kafo
  module DataTypes
    class TypeReference < DataType
      extend Forwardable
      def_delegators :@inner_type, :condition_value, :dump_default, :multivalued?, :to_s, :typecast, :valid?

      def initialize(inner_type)
        @inner_type = DataType.new_from_string(inner_type)
      end
    end

    DataType.register_type('TypeReference', TypeReference)
  end
end
