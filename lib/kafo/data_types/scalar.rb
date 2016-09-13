module Kafo
  module DataTypes
    class Scalar < DataType
      extend Forwardable
      def_delegators :@inner_type, :condition_value, :dump_default, :multivalued?, :typecast, :valid?

      def initialize
        @inner_type = DataTypes::Variant.new('Integer', 'Float', 'String', 'Boolean', 'Regexp')
      end
    end

    DataType.register_type('Scalar', Scalar)
  end
end
