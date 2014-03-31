module Kafo
  module Params
    class Hash < Param
      def value=(value)
        super
        @value = typecast(@value)
      end

      def multivalued?
        true
      end

      def condition_value
        value.inspect
      end

      private

      def typecast(value)
        if value.nil?
          nil
        elsif value.is_a?(::Hash)
          value
        else
          value = [value].flatten
          ::Hash[value.map { |v| v.split(':', 2) }]
        end
      rescue NoMethodError => e
        KafoConfigure.logger.warn "Could not typecast #{value} for parameter #{name}, defaulting to {}"
        return {}
      end
    end
  end
end
