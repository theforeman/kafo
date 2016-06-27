module Kafo
  module DataTypes
    class Pattern < DataType
      def initialize(*regexes)
        @regex_strings = regexes
        @regexes = regexes.map { |r| ::Regexp.new(r) }
      end

      def to_s
        "regexes matching #{@regex_strings.map { |r| "/#{r}/" }.join(' or ')}"
      end

      def valid?(input, errors = [])
        unless input.is_a?(::String)
          errors << "#{input.inspect} is not a valid string"
          return false
        end

        unless @regexes.any? { |r| r.match(input) }
          errors << "#{input} must match one of #{@regexes.join(', ')}"
        end

        return errors.empty?
      end
    end

    DataType.register_type('Pattern', Pattern)
  end
end
