module Params
  class Integer < Param
    def value=(value)
      super
      @value = typecast(@value)
    end

    private

    def typecast(value)
      value.nil? ? nil : value.to_i
    end
  end
end
