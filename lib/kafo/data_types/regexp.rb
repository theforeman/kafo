require 'forwardable'

module Kafo
  module DataTypes
    class Regexp < DataType
      extend Forwardable
      def_delegators :@inner_type, :condition_value, :dump_default, :multivalued?, :typecast, :valid?

      def initialize
        @inner_type = DataTypes::String.new
      end
    end

    DataType.register_type('Regexp', Regexp)
  end
end
