module Kafo
  module Params
    class Integer < Param
      def value=(value)
        super
        @value = typecast(@value)
      end

      private

      def typecast(value)
        value.nil? ? nil : value.to_i
      rescue NoMethodError => e
        KafoConfigure.logger.warn "Could not typecast #{value} for parameter #{name}, defaulting to 0"
        return 0
      end
    end
  end
end
